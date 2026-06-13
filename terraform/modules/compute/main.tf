variable "project_name" { type = string }
variable "env" { type = string }
variable "vpc_cidr" { type = string }
variable "azs" { type = list(string) }
variable "vpc_id" { type = string }
variable "public_subnet_ids" { type = list(string) }
variable "private_subnet_ids" { type = list(string) }
variable "kms_key_arn" { type = string }
variable "lambda_security_group_id" { type = string }
variable "lambda_sg_arn" { type = string }
variable "db_credentials_secret_arn" { type = string }
variable "redis_auth_token_secret_arn" { type = string }
variable "lambda_node_url_az1" { type = string }
variable "lambda_node_url_az2" { type = string }
variable "rds_proxy_endpoint" { type = string }
variable "rds_endpoint" { type = string }
variable "redis_endpoint" { type = string }
variable "redis_port" { type = number }
variable "sqs_queue_url" { type = string }
variable "aws_region" { type = string, default = "us-east-1" }

locals {
  name_prefix = "${var.project_name}-${var.env}"
}

# === 09-sqs.tf ===
resource "aws_sqs_queue" "vote_queue" {
  name                       = "${local.name_prefix}-vote-queue"
  visibility_timeout_seconds = 300
  message_retention_seconds  = 1209600
  max_message_size           = 256000

  kms_master_key_id                 = aws_kms_key.main.arn
  kms_data_key_reuse_period_seconds = 300

  redrive_policy = jsonencode({
    deadLetterTargetArn = aws_sqs_queue.vote_dlq.arn
    maxReceiveCount     = 3
  })

  tags = {
    Name = "${local.name_prefix}-vote-queue"
  }
}

resource "aws_sqs_queue" "vote_dlq" {
  name                      = "${local.name_prefix}-vote-dlq"
  message_retention_seconds = 1209600
  kms_master_key_id         = aws_kms_key.main.arn

  tags = {
    Name = "${local.name_prefix}-vote-dlq"
  }
}

resource "aws_cloudwatch_metric_alarm" "sqs_queue_depth" {
  alarm_name          = "${local.name_prefix}-sqs-queue-depth"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = "2"
  metric_name         = "ApproximateNumberOfMessagesVisible"
  namespace           = "AWS/SQS"
  period              = "60"
  statistic           = "Sum"
  threshold           = "100"
  alarm_description   = "SQS queue depth exceeds 100 messages"

  dimensions = {
    QueueName = aws_sqs_queue.vote_queue.name
  }
}
# === 10-lambdas.tf ===
locals {
  lambda_acceso_zip      = "${path.module}/../lambda/lambda-acceso.zip"
  lambda_despachador_zip = "${path.module}/../lambda/lambda-despachador.zip"
  lambda_procesador_zip  = "${path.module}/../lambda/lambda-procesador.zip"
}

locals {
  lambda_common_env = {
    DATABASE_URL = aws_db_instance.main.address
    PORT         = "8080"
  }
}

# Log Groups
resource "aws_cloudwatch_log_group" "lambda_acceso" {
  for_each          = toset(["az1", "az2"])
  name              = "/aws/lambda/${local.name_prefix}-acceso-${each.key}"
  retention_in_days = 7
}

resource "aws_cloudwatch_log_group" "lambda_despachador" {
  for_each          = toset(["az1", "az2"])
  name              = "/aws/lambda/${local.name_prefix}-despachador-${each.key}"
  retention_in_days = 7
}

resource "aws_cloudwatch_log_group" "lambda_procesador" {
  for_each          = toset(["az1", "az2"])
  name              = "/aws/lambda/${local.name_prefix}-procesador-${each.key}"
  retention_in_days = 14
}

# Lambda Acceso - AZ1
resource "aws_lambda_function" "acceso_az1" {
  function_name    = "${local.name_prefix}-acceso-az1"
  role             = aws_iam_role.lambda.arn
  handler          = "bootstrap"
  runtime          = "provided.al2023"
  timeout          = 30
  memory_size      = 512
  filename         = local.lambda_acceso_zip
  source_code_hash = filebase64sha256(local.lambda_acceso_zip)

  vpc_config {
    subnet_ids         = [aws_subnet.compute["us-east-1a"].id]
    security_group_ids = [aws_security_group.lambda.id]
  }

  environment {
    variables = merge(
      local.lambda_common_env,
      { BLOCKCHAIN_NODE_URL = var.lambda_node_url_az1 }
    )
  }

  reserved_concurrent_executions = 5

  depends_on = [aws_cloudwatch_log_group.lambda_acceso]
}

# Lambda Acceso - AZ2
resource "aws_lambda_function" "acceso_az2" {
  function_name    = "${local.name_prefix}-acceso-az2"
  role             = aws_iam_role.lambda.arn
  handler          = "bootstrap"
  runtime          = "provided.al2023"
  timeout          = 30
  memory_size      = 512
  filename         = local.lambda_acceso_zip
  source_code_hash = filebase64sha256(local.lambda_acceso_zip)

  vpc_config {
    subnet_ids         = [aws_subnet.compute["us-east-1b"].id]
    security_group_ids = [aws_security_group.lambda.id]
  }

  environment {
    variables = merge(
      local.lambda_common_env,
      { BLOCKCHAIN_NODE_URL = var.lambda_node_url_az2 }
    )
  }

  reserved_concurrent_executions = 5

  depends_on = [aws_cloudwatch_log_group.lambda_acceso]
}

# Lambda Despachador - AZ1
resource "aws_lambda_function" "despachador_az1" {
  function_name    = "${local.name_prefix}-despachador-az1"
  role             = aws_iam_role.lambda.arn
  handler          = "bootstrap"
  runtime          = "provided.al2023"
  timeout          = 30
  memory_size      = 256
  filename         = local.lambda_despachador_zip
  source_code_hash = filebase64sha256(local.lambda_despachador_zip)

  vpc_config {
    subnet_ids         = [aws_subnet.compute["us-east-1a"].id]
    security_group_ids = [aws_security_group.lambda.id]
  }

  environment {
    variables = {
      VOTE_QUEUE_URL = aws_sqs_queue.vote_queue.id
    }
  }

  reserved_concurrent_executions = 5

  depends_on = [aws_cloudwatch_log_group.lambda_despachador]
}

# Lambda Despachador - AZ2
resource "aws_lambda_function" "despachador_az2" {
  function_name    = "${local.name_prefix}-despachador-az2"
  role             = aws_iam_role.lambda.arn
  handler          = "bootstrap"
  runtime          = "provided.al2023"
  timeout          = 30
  memory_size      = 256
  filename         = local.lambda_despachador_zip
  source_code_hash = filebase64sha256(local.lambda_despachador_zip)

  vpc_config {
    subnet_ids         = [aws_subnet.compute["us-east-1b"].id]
    security_group_ids = [aws_security_group.lambda.id]
  }

  environment {
    variables = {
      VOTE_QUEUE_URL = aws_sqs_queue.vote_queue.id
    }
  }

  reserved_concurrent_executions = 5

  depends_on = [aws_cloudwatch_log_group.lambda_despachador]
}

# Lambda Procesador - AZ1
resource "aws_lambda_function" "procesador_az1" {
  function_name    = "${local.name_prefix}-procesador-az1"
  role             = aws_iam_role.lambda.arn
  handler          = "bootstrap"
  runtime          = "provided.al2023"
  timeout          = 300
  memory_size      = 1024
  filename         = local.lambda_procesador_zip
  source_code_hash = filebase64sha256(local.lambda_procesador_zip)

  vpc_config {
    subnet_ids         = [aws_subnet.compute["us-east-1a"].id]
    security_group_ids = [aws_security_group.lambda.id]
  }

  environment {
    variables = {
      BLOCKCHAIN_NODE_URL = var.lambda_node_url_az1
    }
  }

  reserved_concurrent_executions = 5

  depends_on = [aws_cloudwatch_log_group.lambda_procesador]
}

# Lambda Procesador - AZ2
resource "aws_lambda_function" "procesador_az2" {
  function_name    = "${local.name_prefix}-procesador-az2"
  role             = aws_iam_role.lambda.arn
  handler          = "bootstrap"
  runtime          = "provided.al2023"
  timeout          = 300
  memory_size      = 1024
  filename         = local.lambda_procesador_zip
  source_code_hash = filebase64sha256(local.lambda_procesador_zip)

  vpc_config {
    subnet_ids         = [aws_subnet.compute["us-east-1b"].id]
    security_group_ids = [aws_security_group.lambda.id]
  }

  environment {
    variables = {
      BLOCKCHAIN_NODE_URL = var.lambda_node_url_az2
    }
  }

  reserved_concurrent_executions = 5

  depends_on = [aws_cloudwatch_log_group.lambda_procesador]
}

# SQS Event Source Mapping
resource "aws_lambda_event_source_mapping" "procesador_az1" {
  event_source_arn                   = aws_sqs_queue.vote_queue.arn
  function_name                      = aws_lambda_function.procesador_az1.arn
  batch_size                         = 10
  maximum_batching_window_in_seconds = 0
}

resource "aws_lambda_event_source_mapping" "procesador_az2" {
  event_source_arn                   = aws_sqs_queue.vote_queue.arn
  function_name                      = aws_lambda_function.procesador_az2.arn
  batch_size                         = 10
  maximum_batching_window_in_seconds = 0
}
# === 11-api-gateway.tf ===
# HTTP API Gateway v2 - Front para las Lambdas
resource "aws_apigatewayv2_api" "main" {
  name          = "${local.name_prefix}-api"
  protocol_type = "HTTP"

  cors_configuration {
    allow_origins  = ["*"]
    allow_methods  = ["GET", "POST", "PUT", "DELETE", "OPTIONS"]
    allow_headers  = ["Content-Type", "Authorization", "X-User-Email", "X-User-Role"]
    expose_headers = ["Content-Type"]
    max_age        = 3600
  }

  tags = {
    Name = "${local.name_prefix}-api"
  }
}

resource "aws_apigatewayv2_stage" "main" {
  api_id      = aws_apigatewayv2_api.main.id
  name        = "$default"
  auto_deploy = true

  default_route_settings {
    detailed_metrics_enabled = true
    logging_level            = "INFO"
  }
}

# Integration: Lambda Acceso (AZ1 y AZ2 comparten integración por backend)
resource "aws_apigatewayv2_integration" "acceso" {
  api_id                 = aws_apigatewayv2_api.main.id
  integration_type       = "AWS_PROXY"
  integration_uri        = aws_lambda_function.acceso_az1.arn
  payload_format_version = "2.0"
}

resource "aws_apigatewayv2_integration" "despachador" {
  api_id                 = aws_apigatewayv2_api.main.id
  integration_type       = "AWS_PROXY"
  integration_uri        = aws_lambda_function.despachador_az1.arn
  payload_format_version = "2.0"
}

# Route: cualquier path a Lambda Acceso
resource "aws_apigatewayv2_route" "acceso" {
  api_id    = aws_apigatewayv2_api.main.id
  route_key = "ANY /{proxy+}"

  target = "integrations/${aws_apigatewayv2_integration.acceso.id}"
}

# Route: /vote a Lambda Despachador
resource "aws_apigatewayv2_route" "despachador" {
  api_id    = aws_apigatewayv2_api.main.id
  route_key = "POST /vote"

  target = "integrations/${aws_apigatewayv2_integration.despachador.id}"
}

# Permisos API Gateway → Lambda
resource "aws_lambda_permission" "acceso_az1" {
  statement_id  = "AllowAPIGatewayInvokeAccesoAZ1"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.acceso_az1.function_name
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${aws_apigatewayv2_api.main.execution_arn}/*/*"
}

resource "aws_lambda_permission" "acceso_az2" {
  statement_id  = "AllowAPIGatewayInvokeAccesoAZ2"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.acceso_az2.function_name
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${aws_apigatewayv2_api.main.execution_arn}/*/*"
}

resource "aws_lambda_permission" "despachador_az1" {
  statement_id  = "AllowAPIGatewayInvokeDespAZ1"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.despachador_az1.function_name
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${aws_apigatewayv2_api.main.execution_arn}/*/*"
}

resource "aws_lambda_permission" "despachador_az2" {
  statement_id  = "AllowAPIGatewayInvokeDespAZ2"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.despachador_az2.function_name
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${aws_apigatewayv2_api.main.execution_arn}/*/*"
}
# === 12-ecs.tf ===
# ECR Repository para blockchain-core
resource "aws_ecr_repository" "blockchain" {
  name = "${local.name_prefix}-blockchain"

  image_scanning_configuration {
    scan_on_push = true
  }

  encryption_configuration {
    encryption_type = "KMS"
    kms_key         = aws_kms_key.main.arn
  }

  tags = {
    Name = "${local.name_prefix}-blockchain"
  }
}

# ECR Lifecycle Policy - Limpiar imágenes antiguas
resource "aws_ecr_lifecycle_policy" "blockchain" {
  repository = aws_ecr_repository.blockchain.name

  policy = jsonencode({
    rules = [
      {
        rulePriority = 1
        description  = "Keep last 10 images"
        selection = {
          tagStatus     = "tagged"
          tagPrefixList = ["v"]
          countType     = "imageCountMoreThan"
          countNumber   = 10
        }
        action = {
          type = "expire"
        }
      },
      {
        rulePriority = 2
        description  = "Expire untagged images after 7 days"
        selection = {
          tagStatus   = "untagged"
          countType   = "sinceImagePushed"
          countUnit   = "days"
          countNumber = 7
        }
        action = {
          type = "expire"
        }
      }
    ]
  })
}

# ECS Cluster
resource "aws_ecs_cluster" "blockchain" {
  name = "${local.name_prefix}-blockchain-cluster"

  setting {
    name  = "containerInsights"
    value = "enabled"
  }

  tags = {
    Name = "${local.name_prefix}-blockchain-cluster"
  }
}

# EFS File System para persistencia
resource "aws_efs_file_system" "blockchain" {
  creation_token = "${local.name_prefix}-blockchain-data"

  encrypted  = true
  kms_key_id = aws_kms_key.main.arn

  lifecycle_policy {
    transition_to_ia = "AFTER_30_DAYS"
  }

  tags = {
    Name = "${local.name_prefix}-blockchain-efs"
  }
}

# EFS Access Point
resource "aws_efs_access_point" "blockchain" {
  file_system_id = aws_efs_file_system.blockchain.id

  posix_user {
    uid = 1000
    gid = 1000
  }

  root_directory {
    path = "/blockchain"
    creation_info {
      owner_uid   = 1000
      owner_gid   = 1000
      permissions = "0755"
    }
  }
}

# EFS Mount Targets (uno por AZ)
resource "aws_efs_mount_target" "blockchain" {
  for_each        = toset(var.azs)
  file_system_id  = aws_efs_file_system.blockchain.id
  subnet_id       = aws_subnet.blockchain[each.key].id
  security_groups = [aws_security_group.efs.id]
}

# CloudWatch Log Group para Blockchain
resource "aws_cloudwatch_log_group" "blockchain" {
  name              = "/ecs/${local.name_prefix}-blockchain"
  retention_in_days = 14
}

# ECS Task Definition
resource "aws_ecs_task_definition" "blockchain" {
  family                   = "${local.name_prefix}-blockchain"
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  cpu                      = "256"
  memory                   = "512"
  execution_role_arn       = aws_iam_role.ecs_task_execution.arn

  volume {
    name = "blockchain-data"
    efs_volume_configuration {
      file_system_id     = aws_efs_file_system.blockchain.id
      transit_encryption = "ENABLED"
      authorization_config {
        access_point_id = aws_efs_access_point.blockchain.id
      }
    }
  }

  container_definitions = jsonencode([
    {
      name      = "blockchain-node"
      image     = "${aws_ecr_repository.blockchain.repository_url}:latest"
      essential = true
      portMappings = [
        {
          containerPort = 9944
          hostPort      = 9944
          protocol      = "tcp"
        }
      ]
      mountPoints = [
        {
          sourceVolume  = "blockchain-data"
          containerPath = "/data/db"
        }
      ]
      healthCheck = {
        command     = ["CMD-SHELL", "curl -f http://localhost:9944/health || exit 1"]
        interval    = 30
        timeout     = 5
        retries     = 3
        startPeriod = 10
      }
      logConfiguration = {
        logDriver = "awslogs"
        options = {
          "awslogs-group"         = aws_cloudwatch_log_group.blockchain.name
          "awslogs-region"        = var.aws_region
          "awslogs-stream-prefix" = "blockchain"
        }
      }
      environment = [
        { name = "PORT", value = "9944" },
        { name = "RUST_LOG", value = "blockchain_core=info" }
      ]
    }
  ])

  tags = {
    Name = "${local.name_prefix}-blockchain-task"
  }
}

# ECS Service
resource "aws_ecs_service" "blockchain" {
  name            = "${local.name_prefix}-blockchain-service"
  cluster         = aws_ecs_cluster.blockchain.id
  task_definition = aws_ecs_task_definition.blockchain.arn
  desired_count   = 2
  launch_type     = "FARGATE"

  network_configuration {
    subnets          = [for s in aws_subnet.blockchain : s.id]
    security_groups  = [aws_security_group.ecs.id]
    assign_public_ip = false
  }

  load_balancer {
    target_group_arn = aws_lb_target_group.blockchain.arn
    container_name   = "blockchain-node"
    container_port   = 9944
  }

  depends_on = [aws_lb_listener.blockchain]

  tags = {
    Name = "${local.name_prefix}-blockchain-service"
  }
}

output "blockchain_alb_endpoint" {
  value = aws_lb.blockchain.dns_name
}
# === 13-ecs-alb.tf ===
# Internal ALB para Blockchain Nodes
resource "aws_lb" "blockchain" {
  name               = "${local.name_prefix}-blockchain-alb"
  internal           = true
  load_balancer_type = "application"
  security_groups    = [aws_security_group.ecs.id]
  subnets            = [for s in aws_subnet.blockchain : s.id]

  tags = {
    Name = "${local.name_prefix}-blockchain-alb"
  }
}

resource "aws_lb_target_group" "blockchain" {
  name     = "${local.name_prefix}-blockchain-tg"
  port     = 9944
  protocol = "HTTP"
  vpc_id   = aws_vpc.main.id

  health_check {
    path                = "/health"
    interval            = 30
    timeout             = 5
    healthy_threshold   = 2
    unhealthy_threshold = 5
    matcher             = "200"
  }
}

resource "aws_lb_listener" "blockchain" {
  load_balancer_arn = aws_lb.blockchain.arn
  port              = "9944"
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.blockchain.arn
  }
}

resource "aws_lb_target_group_attachment" "blockchain_az1" {
  target_group_arn = aws_lb_target_group.blockchain.arn
  target_id        = aws_ecs_service.blockchain.id
  port             = 9944
}
output "sqs_queue_url" { value = aws_sqs_queue.vote_queue.id }
output "api_gateway_endpoint" { value = aws_apigatewayv2_api.main.api_endpoint }
output "api_gateway_id" { value = aws_apigatewayv2_api.main.id }
output "lambda_acceso_az1_arn" { value = aws_lambda_function.acceso_az1.arn }
output "lambda_acceso_az2_arn" { value = aws_lambda_function.acceso_az2.arn }
output "lambda_despachador_az1_arn" { value = aws_lambda_function.despachador_az1.arn }
output "lambda_despachador_az2_arn" { value = aws_lambda_function.despachador_az2.arn }
output "lambda_procesador_az1_arn" { value = aws_lambda_function.procesador_az1.arn }
output "lambda_procesador_az2_arn" { value = aws_lambda_function.procesador_az2.arn }
