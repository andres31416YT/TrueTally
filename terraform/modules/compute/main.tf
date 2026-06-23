variable "project_name" { type = string }
variable "env" { type = string }
variable "vpc_id" { type = string }
variable "public_subnet_ids" { type = list(string) }
variable "private_subnet_ids" { type = list(string) }
variable "blockchain_subnet_ids" { type = list(string) }
variable "kms_key_arn" { type = string }
variable "lambda_security_group_id" { type = string }
variable "lambda_sg_arn" { type = string }
variable "db_credentials_secret_arn" { type = string }
variable "redis_auth_token_secret_arn" { type = string }
variable "vote_queue_arn" { type = string }
variable "vote_queue_url" { type = string }
variable "lambda_node_url_az1" { type = string }
variable "lambda_node_url_az2" { type = string }
variable "ecr_repository_url" { type = string }
variable "lambda_zip_path" { type = string }

locals {
  name_prefix = "${var.project_name}-${var.env}"
}

# IAM Role for Lambda
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

resource "aws_iam_role_policy" "lambda_ssm" {
  name = "${local.name_prefix}-lambda-ssm"
  role = aws_iam_role.lambda.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "ssm:DescribeInstanceInformation",
          "ssm:StartSession",
          "ssm:SendCommand"
        ]
        Resource = "*"
      },
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
      {
        Effect = "Allow"
        Action = [
          "sqs:ReceiveMessage",
          "sqs:DeleteMessage",
          "sqs:GetQueueAttributes"
        ]
        Resource = var.vote_queue_arn
      }
    ]
  })
}

# Lambda functions
resource "aws_lambda_function" "acceso" {
  function_name = "${local.name_prefix}-acceso"
  filename      = "${var.lambda_zip_path}/lambda-acceso.zip"
  role          = aws_iam_role.lambda.arn
  handler       = "bootstrap"
  runtime       = "provided.al2"

  vpc_config {
    subnet_ids         = var.private_subnet_ids
    security_group_ids = [var.lambda_security_group_id]
  }

  environment {
    variables = {
      DB_CREDENTIALS_ARN = var.db_credentials_secret_arn
    }
  }
}

resource "aws_lambda_function" "despachador" {
  function_name = "${local.name_prefix}-despachador"
  filename      = "${var.lambda_zip_path}/lambda-despachador.zip"
  role          = aws_iam_role.lambda.arn
  handler       = "bootstrap"
  runtime       = "provided.al2"

  vpc_config {
    subnet_ids         = var.private_subnet_ids
    security_group_ids = [var.lambda_security_group_id]
  }

  environment {
    variables = {
      VOTE_QUEUE_URL = var.vote_queue_url
    }
  }
}

resource "aws_lambda_function" "procesador" {
  function_name = "${local.name_prefix}-procesador"
  filename      = "${var.lambda_zip_path}/lambda-procesador.zip"
  role          = aws_iam_role.lambda.arn
  handler       = "bootstrap"
  runtime       = "provided.al2"

  vpc_config {
    subnet_ids         = var.private_subnet_ids
    security_group_ids = [var.lambda_security_group_id]
  }

  environment {
    variables = {
      NODE_URL_AZ1 = var.lambda_node_url_az1
      NODE_URL_AZ2 = var.lambda_node_url_az2
    }
  }
}

# ECS Cluster for Blockchain
resource "aws_ecs_cluster" "blockchain" {
  name = "${local.name_prefix}-blockchain-cluster"
}

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

resource "aws_iam_role_policy_attachment" "ecs_task_ecr" {
  role       = aws_iam_role.ecs_task.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly"
}

resource "aws_iam_role_policy_attachment" "ecs_task_execution" {
  role       = aws_iam_role.ecs_task.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
}

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

# EFS for Blockchain Node persistence
resource "aws_efs_file_system" "blockchain" {
  creation_token = "${local.name_prefix}-blockchain-efs"
  encrypted      = true
  kms_key_id     = var.kms_key_arn

  tags = {
    Name = "${local.name_prefix}-blockchain-efs"
  }
}

resource "aws_security_group_rule" "efs_inbound" {
  type                     = "ingress"
  from_port                = 2049
  to_port                  = 2049
  protocol                 = "tcp"
  security_group_id        = var.lambda_security_group_id
  source_security_group_id = var.lambda_security_group_id
}

resource "aws_efs_mount_target" "blockchain" {
  count = length(var.blockchain_subnet_ids)

  file_system_id  = aws_efs_file_system.blockchain.id
  subnet_id       = var.blockchain_subnet_ids[count.index]
  security_groups = [var.lambda_security_group_id]
}

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

# ECS Task Definition with EFS volume
resource "aws_ecs_task_definition" "blockchain" {
  family                   = "${local.name_prefix}-blockchain"
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  cpu                      = "512"
  memory                   = "1024"
  execution_role_arn       = aws_iam_role.ecs_task.arn
  task_role_arn            = aws_iam_role.ecs_task.arn

  container_definitions = jsonencode([{
    name                   = "blockchain-node"
    image                  = "${var.ecr_repository_url}:latest"
    essential              = true
    privileged             = false
    readonlyRootFilesystem = false
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

resource "aws_ecs_service" "blockchain" {
  name            = "${local.name_prefix}-blockchain-service"
  cluster         = aws_ecs_cluster.blockchain.id
  task_definition = aws_ecs_task_definition.blockchain.arn
  desired_count   = 1

  network_configuration {
    subnets          = var.blockchain_subnet_ids
    security_groups  = [var.lambda_security_group_id]
    assign_public_ip = false
  }

  deployment_controller {
    type = "ECS"
  }

  deployment_circuit_breaker {
    enable   = true
    rollback = true
  }
}