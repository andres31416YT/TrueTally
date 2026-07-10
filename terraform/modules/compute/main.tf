locals {
  name_prefix = "${var.project_name}-${var.env}"

  # Map AZ names to subnet IDs for EFS mount targets
  blockchain_mount_targets = {
    for i, az in var.azs :
    az => var.blockchain_subnet_ids[i]
  }
}

# IAM Role for Lambda functions
resource "aws_iam_role" "lambda" {
  name = "${local.name_prefix}-lambda-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "lambda.amazonaws.com"
        }
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "lambda_basic" {
  role       = aws_iam_role.lambda.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}

resource "aws_iam_role_policy_attachment" "lambda_vpc" {
  role       = aws_iam_role.lambda.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaVPCAccessExecutionRole"
}

resource "aws_iam_role_policy_attachment" "lambda_xray" {
  role       = aws_iam_role.lambda.name
  policy_arn = "arn:aws:iam::aws:policy/AWSXRayDaemonWriteAccess"
}

# Lambda IAM policy for SSM, Secrets Manager, and SQS access
resource "aws_iam_role_policy" "lambda_ssm" {
  name = "${local.name_prefix}-lambda-ssm"
  role = aws_iam_role.lambda.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      # Allow SSM session management
      {
        Effect = "Allow"
        Action = [
          "ssm:StartSession"
        ]
        Resource = "arn:aws:ssm:*:*:managed-instance/*"
      },
      # Allow SSM command sending
      {
        Effect = "Allow"
        Action = [
          "ssm:SendCommand"
        ]
        Resource = "arn:aws:ssm:*:*:document/*"
      },
      # Allow reading DB credentials from Secrets Manager
      {
        Effect = "Allow"
        Action = [
          "secretsmanager:GetSecretValue"
        ]
        Resource = [
          var.db_credentials_secret_arn,
          var.redis_auth_token_secret_arn
        ]
      },
      # Allow receiving messages from vote queue
      {
        Effect = "Allow"
        Action = [
          "sqs:ReceiveMessage",
          "sqs:DeleteMessage",
          "sqs:GetQueueAttributes"
        ]
        Resource = var.vote_queue_arn
      },
      # Allow sending messages to DLQ
      {
        Effect = "Allow"
        Action = [
          "sqs:SendMessage"
        ]
        Resource = var.dlq_arn
      }
    ]
  })
}

# Lambda Functions
# Deployment is handled by Ansible after initial creation
resource "aws_lambda_function" "acceso" {
  function_name                  = "${local.name_prefix}-acceso"
  filename                       = "${var.lambda_zip_path}/lambda-acceso.zip"
  role                           = aws_iam_role.lambda.arn
  handler                        = "bootstrap"
  runtime                        = "provided.al2"
  kms_key_arn                    = var.kms_key_arn
  reserved_concurrent_executions = var.lambda_reserved_concurrent_executions

  vpc_config {
    subnet_ids         = var.private_subnet_ids
    security_group_ids = [var.lambda_security_group_id]
  }

  dead_letter_config {
    target_arn = var.dlq_arn
  }

  environment {
    variables = {
      DB_CREDENTIALS_ARN = var.db_credentials_secret_arn
      BLOCKCHAIN_NODE_URL = local.blockchain_service_dns != "" ? "http://${local.blockchain_service_dns}:9944" : "http://localhost:9944"
    }
  }

  tracing_config {
    mode = "Active"
  }
}

# Lambda despachador: receives votes from frontend and sends to SQS queue
resource "aws_lambda_function" "despachador" {
  function_name                  = "${local.name_prefix}-despachador"
  filename                       = "${var.lambda_zip_path}/lambda-despachador.zip"
  role                           = aws_iam_role.lambda.arn
  handler                        = "bootstrap"
  runtime                        = "provided.al2"
  kms_key_arn                    = var.kms_key_arn
  reserved_concurrent_executions = var.lambda_reserved_concurrent_executions

  vpc_config {
    subnet_ids         = var.private_subnet_ids
    security_group_ids = [var.lambda_security_group_id]
  }

  dead_letter_config {
    target_arn = var.dlq_arn
  }

  environment {
    variables = {
      VOTE_QUEUE_URL = var.vote_queue_url
    }
  }

  tracing_config {
    mode = "Active"
  }
}

# Lambda procesador: processes votes from SQS and updates blockchain
resource "aws_lambda_function" "procesador" {
  function_name                  = "${local.name_prefix}-procesador"
  filename                       = "${var.lambda_zip_path}/lambda-procesador.zip"
  role                           = aws_iam_role.lambda.arn
  handler                        = "bootstrap"
  runtime                        = "provided.al2"
  kms_key_arn                    = var.kms_key_arn
  reserved_concurrent_executions = var.lambda_reserved_concurrent_executions

  vpc_config {
    subnet_ids         = var.private_subnet_ids
    security_group_ids = [var.lambda_security_group_id]
  }

  dead_letter_config {
    target_arn = var.dlq_arn
  }

  environment {
    variables = {
      BLOCKCHAIN_NODE_URL = local.blockchain_service_dns != "" ? "http://${local.blockchain_service_dns}:9944" : "http://localhost:9944"
    }
  }

  tracing_config {
    mode = "Active"
  }
}

# Event Source Mapping: SQS vote queue -> lambda-procesador
# Consume los votos encolados por lambda-despachador y los escribe en la blockchain.
resource "aws_lambda_event_source_mapping" "procesador_vote" {
  event_source_arn        = var.vote_queue_arn
  function_name            = aws_lambda_function.procesador.arn
  batch_size               = 5
  function_response_types  = ["ReportBatchItemFailures"]
}

# ECS Cluster for Blockchain node
resource "aws_ecs_cluster" "blockchain" {
  name = "${local.name_prefix}-blockchain-cluster"

  setting {
    name  = "containerInsights"
    value = "enabled"
  }
}

# IAM role for ECS tasks (blockchain container)
resource "aws_iam_role" "ecs_task" {
  name = "${local.name_prefix}-ecs-task-role"

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

# IAM role for ECS task execution (pulling images, writing logs)
resource "aws_iam_role" "ecs_execution" {
  name = "${local.name_prefix}-ecs-execution-role"

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

resource "aws_iam_role_policy_attachment" "ecs_task_ecr" {
  role       = aws_iam_role.ecs_execution.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly"
}

resource "aws_iam_role_policy_attachment" "ecs_execution_task" {
  role       = aws_iam_role.ecs_execution.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
}

resource "aws_iam_role_policy" "ecs_execution_service_discovery" {
  name = "${local.name_prefix}-ecs-execution-sd"
  role = aws_iam_role.ecs_execution.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "servicediscovery:DiscoverInstances",
          "servicediscovery:GetInstances",
          "servicediscovery:RegisterInstance",
          "servicediscovery:DeregisterInstance"
        ]
        Resource = aws_service_discovery_service.blockchain.arn
      }
    ]
  })
}

# Policy allowing ECS tasks to mount EFS filesystem
resource "aws_iam_role_policy" "ecs_task_efs" {
  name = "${local.name_prefix}-ecs-efs"
  role = aws_iam_role.ecs_task.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "elasticfilesystem:ClientMount",
          "elasticfilesystem:ClientWrite",
          "elasticfilesystem:ClientRootAccess"
        ]
        Resource = aws_efs_file_system.blockchain.arn
      }
    ]
  })
}

# EFS filesystem for blockchain node state persistence
resource "aws_efs_file_system" "blockchain" {
  creation_token = "${local.name_prefix}-blockchain-efs"
  encrypted      = true
  kms_key_id     = var.kms_key_arn

  tags = {
    Name = "${local.name_prefix}-blockchain-efs"
  }
}

# Mount targets for EFS in each availability zone
resource "aws_efs_mount_target" "blockchain" {
  for_each = local.blockchain_mount_targets

  file_system_id  = aws_efs_file_system.blockchain.id
  subnet_id       = each.value
  security_groups = [var.blockchain_security_group_id]
}

# EFS access point for ECS container mounting
resource "aws_efs_access_point" "blockchain" {
  file_system_id = aws_efs_file_system.blockchain.id

  posix_user {
    gid = 1000
    uid = 1000
  }

  root_directory {
    path = "/blockchain"
    creation_info {
      owner_gid   = 1000
      owner_uid   = 1000
      permissions = "755"
    }
  }
}

# ECS Task Definition for blockchain node with EFS volume mount
resource "aws_ecs_task_definition" "blockchain" {
  family                   = "${local.name_prefix}-blockchain"
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  cpu                      = "512"
  memory                   = "1024"
  execution_role_arn       = aws_iam_role.ecs_execution.arn
  task_role_arn            = aws_iam_role.ecs_task.arn

  container_definitions = jsonencode([{
    name                   = "blockchain-node"
    image                  = "${var.ecr_repository_url}:latest"
    essential              = true
    privileged             = false
    readonlyRootFilesystem = true
    logConfiguration = {
      logDriver = "awslogs"
      options = {
        "awslogs-group"         = "/ecs/${local.name_prefix}-blockchain"
        "awslogs-region"        = var.aws_region
        "awslogs-stream-prefix" = "ecs"
      }
    }
    portMappings = [{
      containerPort = 9944
      hostPort      = 9944
    }]
    mountPoints = [{
      sourceVolume  = "blockchain-efs"
      containerPath = "/data"
      readOnly      = false
    }]
  }])

  volume {
    name = "blockchain-efs"
    efs_volume_configuration {
      file_system_id     = aws_efs_file_system.blockchain.id
      transit_encryption = "ENABLED"
      authorization_config {
        access_point_id = aws_efs_access_point.blockchain.id
        iam             = "ENABLED"
      }
    }
  }
}

# ECS Service running the blockchain node
resource "aws_ecs_service" "blockchain" {
  name            = "${local.name_prefix}-blockchain-service"
  cluster         = aws_ecs_cluster.blockchain.id
  task_definition = aws_ecs_task_definition.blockchain.arn
  desired_count   = 1
  launch_type     = "FARGATE"

  network_configuration {
    subnets          = var.blockchain_subnet_ids
    security_groups  = [var.blockchain_security_group_id]
    assign_public_ip = true
  }

  deployment_controller {
    type = "ECS"
  }

  deployment_circuit_breaker {
    enable   = true
    rollback = true
  }

  service_registries {
    registry_arn = aws_service_discovery_service.blockchain.arn
  }
}

# Service Discovery for blockchain node (stable DNS endpoint)
resource "aws_service_discovery_service" "blockchain" {
  name = "blockchain"

  dns_config {
    namespace_id = var.service_discovery_namespace_id
    dns_records {
      type = "A"
      ttl  = 60
    }
  }

  tags = {
    Name = "${local.name_prefix}-blockchain-sd"
  }
}

locals {
  blockchain_service_dns = "blockchain.${var.service_discovery_namespace_name}"
}

output "blockchain_service_dns" {
  value = local.blockchain_service_dns
}