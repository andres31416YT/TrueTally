locals {
  lambda_runtime   = "provided"
  lambda_arch      = "arm64"
  lambda_node_url  = "http://${aws_eip.blockchain[0].public_ip}:9944"
  lambda_db_url    = local.env == "prod" ? 
                      "postgresql://${local.db_creds.username}:${local.db_creds.password}@${aws_db_proxy.main[0].endpoint}:5432/${aws_db_instance.main.db_name}?sslmode=require" :
                      "postgresql://${local.db_creds.username}:${local.db_creds.password}@${aws_db_instance.main.address}:5432/${aws_db_instance.main.db_name}?sslmode=require"
  lambda_sqs_url   = aws_sqs_queue.vote_queue.id
  lambda_dlq_url   = aws_sqs_queue.vote_dlq.id
  lambda_redis_url = "rediss://:${random_string.redis_password.result}@${aws_elasticache_replication_group.main.primary_endpoint_address}:6379"
}

resource "aws_sqs_queue" "vote_queue" {
  name = "${local.project_name}-${local.env}-vote-queue"

  visibility_timeout_seconds = 60
  message_retention_seconds  = 345600

  kms_master_key_id = aws_kms_key.main.arn

  tags = merge(
    local.common_tags,
    {
      Name = "${local.project_name}-${local.env}-vote-queue"
    }
  )
}

resource "aws_sqs_queue" "vote_dlq" {
  name = "${local.project_name}-${local.env}-vote-dlq"

  message_retention_seconds = 1209600

  kms_master_key_id = aws_kms_key.main.arn

  tags = merge(
    local.common_tags,
    {
      Name = "${local.project_name}-${local.env}-vote-dlq"
    }
  )
}

resource "aws_sqs_queue_redrive_policy" "vote_queue" {
  queue_url = aws_sqs_queue.vote_queue.id

  redrive_policy = jsonencode({
    deadLetterTargetArn = aws_sqs_queue.vote_dlq.arn
    maxReceiveCount     = 3
  })
}

resource "aws_eip" "blockchain" {
  count  = 1
  domain = "vpc"

  tags = merge(
    local.common_tags,
    {
      Name = "${local.project_name}-${local.env}-blockchain-eip"
    }
  )
}

resource "aws_security_group" "ecs" {
  name_prefix = "${local.project_name}-${local.env}-ecs-"
  description = "Security group for ${local.project_name} ${local.env} ECS tasks"
  vpc_id      = aws_vpc.main.id

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = merge(
    local.common_tags,
    {
      Name = "${local.project_name}-${local.env}-ecs-sg"
    }
  )
}

resource "aws_ecr_repository" "blockchain" {
  name = "${local.project_name}-${local.env}-blockchain"

  image_scanning_configuration {
    scan_on_push = true
  }

  encryption_configuration {
    encryption_type = "KMS"
    kms_key         = aws_kms_key.main.arn
  }

  tags = merge(
    local.common_tags,
    {
      Name = "${local.project_name}-${local.env}-blockchain-ecr"
    }
  )
}

resource "aws_efs_file_system" "blockchain" {
  creation_token = "${local.project_name}-${local.env}-blockchain-data"

  encrypted  = true
  kms_key_id = aws_kms_key.main.arn

  lifecycle_policy {
    transition_to_ia = "AFTER_30_DAYS"
  }

  tags = merge(
    local.common_tags,
    {
      Name = "${local.project_name}-${local.env}-blockchain-data"
    }
  )
}

resource "aws_efs_access_point" "blockchain" {
  file_system_id = aws_efs_file_system.blockchain.id

  posix_user {
    gid = 1000
    uid = 1000
  }

  root_directory {
    path = "/data"
    creation_info {
      owner_gid   = 1000
      owner_uid   = 1000
      permissions = "755"
    }
  }
}

resource "aws_efs_mount_target" "blockchain" {
  for_each = aws_subnet.private

  file_system_id  = aws_efs_file_system.blockchain.id
  subnet_id       = each.value.id
  security_groups = [aws_security_group.efs_mount.id]
}

resource "aws_ecs_cluster" "main" {
  name = "${local.project_name}-${local.env}-cluster"

  setting {
    name  = "containerInsights"
    value = "enabled"
  }

  tags = merge(
    local.common_tags,
    {
      Name = "${local.project_name}-${local.env}-cluster"
    }
  )
}

resource "aws_ecs_task_definition" "blockchain" {
  family                   = "${local.project_name}-${local.env}-blockchain"
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  cpu                      = "256"
  memory                   = "512"
  execution_role_arn       = aws_iam_role.ecs_execution.arn
  task_role_arn            = aws_iam_role.ecs_task.arn

  container_definitions = jsonencode([
    {
      name      = "blockchain"
      image     = "${aws_ecr_repository.blockchain.repository_url}:latest"
      essential = true
      portMappings = [
        {
          containerPort = 9944
          hostPort      = 9944
        }
      ]
      environment = [
        {
          name  = "RUST_LOG"
          value = "info"
        }
      ]
      mountPoints = [
        {
          sourceVolume  = "blockchain-data"
          containerPath = "/app/data"
        }
      ]
      logConfiguration = {
        logDriver = "awslogs"
        options = {
          "awslogs-group"         = "/ecs/${local.project_name}-${local.env}"
          "awslogs-region"        = local.region
          "awslogs-stream-prefix" = "blockchain"
        }
      }
    }
  ])

  volume {
    name = "blockchain-data"
    efs_volume_configuration {
      file_system_id     = aws_efs_file_system.blockchain.id
      root_directory     = "/"
      transit_encryption = "ENABLED"
      authorization_config {
        access_point_id = aws_efs_access_point.blockchain.id
        iam             = "ENABLED"
      }
    }
  }

  tags = merge(
    local.common_tags,
    {
      Name = "${local.project_name}-${local.env}-blockchain-task"
    }
  )
}

resource "aws_iam_role" "ecs_execution" {
  name = "${local.project_name}-${local.env}-ecs-execution-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "ecs-tasks.amazonaws.com"
        }
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "ecs_execution" {
  role       = aws_iam_role.ecs_execution.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
}

resource "aws_iam_role_policy" "ecs_execution_kms" {
  name = "${local.project_name}-${local.env}-ecs-execution-kms"
  role = aws_iam_role.ecs_execution.id

  policy = data.aws_iam_policy_document.ecs_execution_kms.json
}

data "aws_iam_policy_document" "ecs_execution_kms" {
  statement {
    sid       = "KMSDecrypt"
    effect    = "Allow"
    actions   = ["kms:Decrypt", "kms:GenerateDataKey"]
    resources = [aws_kms_key.main.arn]
  }
}

resource "aws_iam_role" "ecs_task" {
  name = "${local.project_name}-${local.env}-ecs-task-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "ecs-tasks.amazonaws.com"
        }
      }
    ]
  })
}

resource "aws_iam_role_policy" "ecs_task_efs" {
  name = "${local.project_name}-${local.env}-ecs-task-efs"
  role = aws_iam_role.ecs_task.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "elasticfilesystem:ClientMount",
          "elasticfilesystem:ClientWrite"
        ]
        Resource = aws_efs_file_system.blockchain.arn
      }
    ]
  })
}

resource "aws_ecs_service" "blockchain" {
  name            = "${local.project_name}-${local.env}-blockchain"
  cluster         = aws_ecs_cluster.main.id
  task_definition = aws_ecs_task_definition.blockchain.arn
  desired_count   = 1
  launch_type     = "FARGATE"

  network_configuration {
    subnets          = values(aws_subnet.public)[*].id
    security_groups  = [aws_security_group.ecs.id, aws_security_group.blockchain.id]
    assign_public_ip = true
  }

  tags = merge(
    local.common_tags,
    {
      Name = "${local.project_name}-${local.env}-blockchain-service"
    }
  )
}

resource "aws_lb" "blockchain" {
  name               = "${local.project_name}-${local.env}-blockchain-alb"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.ecs.id]
  subnets            = [for s in aws_subnet.public : s.id]

  tags = merge(
    local.common_tags,
    {
      Name = "${local.project_name}-${local.env}-blockchain-alb"
    }
  )
}

resource "aws_lb_target_group" "blockchain" {
  name     = "${local.project_name}-${local.env}-blockchain-tg"
  port     = 9944
  protocol = "HTTP"
  vpc_id   = aws_vpc.main.id

  health_check {
    path                = "/"
    matcher             = "200-399"
    interval            = 30
    timeout             = 5
    healthy_threshold   = 2
    unhealthy_threshold = 3
  }
}

resource "aws_lb_listener" "blockchain" {
  load_balancer_arn = aws_lb.blockchain.arn
  port              = "80"
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.blockchain.arn
  }
}

resource "aws_lambda_function" "acceso" {
  function_name    = "${local.project_name}-${local.env}-acceso"
  description      = "API Gateway for ${local.project_name}"
  role             = aws_iam_role.lambda.arn
  runtime          = local.lambda_runtime
  architectures    = [local.lambda_arch]
  filename         = "lambda-acceso.zip"
  source_code_hash = filebase64sha256("lambda-acceso.zip")
  handler          = "bootstrap"

  environment {
    variables = {
      DATABASE_URL  = local.lambda_db_url
      REDIS_URL     = local.lambda_redis_url
      NODE_URL      = local.lambda_node_url
      SQS_QUEUE_URL = local.lambda_sqs_url
      SQS_DLQ_URL   = local.lambda_dlq_url
    }
  }

  vpc_config {
    subnet_ids         = [for s in aws_subnet.private : s.id]
    security_group_ids = [aws_security_group.lambda.id]
  }

  timeout     = 30
  memory_size = 256

  tags = merge(
    local.common_tags,
    {
      Name = "${local.project_name}-${local.env}-acceso"
    }
  )
}

resource "aws_lambda_function" "despachador" {
  function_name    = "${local.project_name}-${local.env}-despachador"
  description      = "Vote dispatcher for ${local.project_name}"
  role             = aws_iam_role.lambda.arn
  runtime          = local.lambda_runtime
  architectures    = [local.lambda_arch]
  filename         = "lambda-despachador.zip"
  source_code_hash = filebase64sha256("lambda-despachador.zip")
  handler          = "bootstrap"

  environment {
    variables = {
      DATABASE_URL  = local.lambda_db_url
      REDIS_URL     = local.lambda_redis_url
      NODE_URL      = local.lambda_node_url
      SQS_QUEUE_URL = local.lambda_sqs_url
      SQS_DLQ_URL   = local.lambda_dlq_url
    }
  }

  vpc_config {
    subnet_ids         = [for s in aws_subnet.private : s.id]
    security_group_ids = [aws_security_group.lambda.id]
  }

  timeout     = 30
  memory_size = 256

  tags = merge(
    local.common_tags,
    {
      Name = "${local.project_name}-${local.env}-despachador"
    }
  )
}

resource "aws_lambda_function" "procesador" {
  function_name    = "${local.project_name}-${local.env}-procesador"
  description      = "Vote processor for ${local.project_name}"
  role             = aws_iam_role.lambda.arn
  runtime          = local.lambda_runtime
  architectures    = [local.lambda_arch]
  filename         = "lambda-procesador.zip"
  source_code_hash = filebase64sha256("lambda-procesador.zip")
  handler          = "bootstrap"

  environment {
    variables = {
      DATABASE_URL  = local.lambda_db_url
      REDIS_URL     = local.lambda_redis_url
      NODE_URL      = local.lambda_node_url
      SQS_QUEUE_URL = local.lambda_sqs_url
      SQS_DLQ_URL   = local.lambda_dlq_url
    }
  }

  vpc_config {
    subnet_ids         = [for s in aws_subnet.private : s.id]
    security_group_ids = [aws_security_group.lambda.id]
  }

  timeout     = 300
  memory_size = 512

  tags = merge(
    local.common_tags,
    {
      Name = "${local.project_name}-${local.env}-procesador"
    }
  )
}

resource "aws_lambda_event_source_mapping" "sqs_procesador" {
  event_source_arn                   = aws_sqs_queue.vote_queue.arn
  function_name                      = aws_lambda_function.procesador.arn
  batch_size                         = 10
  maximum_batching_window_in_seconds = 5
}
