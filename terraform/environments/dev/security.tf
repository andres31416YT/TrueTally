locals {
  common_tags = {
    Project     = local.project_name
    Environment = local.env
  }
}

resource "random_string" "db_password" {
  length  = 16
  special = false

}

resource "aws_kms_key" "main" {
  description             = "KMS key for ${local.project_name} ${local.env}"
  deletion_window_in_days = 10
  enable_key_rotation     = true

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "Enable IAM User Permissions"
        Effect = "Allow"
        Principal = {
          AWS = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:root"
        }
        Action   = "kms:*"
        Resource = "*"
      }
    ]
  })

  tags = merge(
    local.common_tags,
    {
      Name = "${local.project_name}-${local.env}-kms"
    }
  )
}

resource "aws_kms_alias" "main" {
  name          = "alias/${local.project_name}-${local.env}"
  target_key_id = aws_kms_key.main.key_id
}

data "aws_caller_identity" "current" {}

resource "aws_secretsmanager_secret" "db_credentials" {
  name        = "${local.project_name}-${local.env}-db-credentials"
  description = "DB credentials for ${local.project_name} ${local.env}"
  kms_key_id  = aws_kms_key.main.arn

  tags = merge(
    local.common_tags,
    {
      Name = "${local.project_name}-${local.env}-db-credentials"
    }
  )
}

resource "aws_secretsmanager_secret_version" "db_credentials" {
  secret_id = aws_secretsmanager_secret.db_credentials.id
  secret_string = jsonencode({
    username = "truetally"
    password = random_string.db_password.result
    engine   = "postgres"
    port     = 5432
  })
}

resource "aws_iam_role" "lambda" {
  name = "${local.project_name}-${local.env}-lambda-role"

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

resource "aws_iam_policy" "lambda" {
  name        = "${local.project_name}-${local.env}-lambda-policy"
  description = "Policy for ${local.project_name} ${local.env} Lambda functions"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "logs:CreateLogGroup",
          "logs:CreateLogStream",
          "logs:PutLogEvents"
        ]
        Resource = "arn:aws:logs:*:*:*"
      },
      {
        Effect = "Allow"
        Action = [
          "sqs:ReceiveMessage",
          "sqs:DeleteMessage",
          "sqs:GetQueueAttributes"
        ]
        Resource = [
          aws_sqs_queue.vote_queue.arn,
          aws_sqs_queue.vote_dlq.arn
        ]
      },
      {
        Effect = "Allow"
        Action = [
          "secretsmanager:GetSecretValue"
        ]
        Resource = aws_secretsmanager_secret.db_credentials.arn
      },
      {
        Effect = "Allow"
        Action = [
          "rds-db:connect"
        ]
        Resource = "*"
      },
      {
        Effect = "Allow"
        Action = [
          "ec2:CreateNetworkInterface",
          "ec2:DescribeNetworkInterfaces",
          "ec2:DeleteNetworkInterface"
        ]
        Resource = "*"
      },
      {
        Effect = "Allow"
        Action = [
          "elasticache:Connect"
        ]
        Resource = "*"
      },
      {
        Effect = "Allow"
        Action = [
          "ecr:GetDownloadUrlForLayer",
          "ecr:BatchGetImage",
          "ecr:BatchCheckLayerAvailability"
        ]
        Resource = "*"
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "lambda" {
  role       = aws_iam_role.lambda.name
  policy_arn = aws_iam_policy.lambda.arn
}

resource "aws_iam_role_policy_attachment" "lambda_basic" {
  role       = aws_iam_role.lambda.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}

resource "aws_iam_role_policy_attachment" "lambda_vpc" {
  role       = aws_iam_role.lambda.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaVPCAccessExecutionRole"
}

resource "aws_security_group" "lambda" {
  name_prefix = "${local.project_name}-${local.env}-lambda-"
  description = "Security group for ${local.project_name} ${local.env} Lambda functions"
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
      Name = "${local.project_name}-${local.env}-lambda-sg"
    }
  )
}

resource "aws_security_group" "rds" {
  name_prefix = "${local.project_name}-${local.env}-rds-"
  description = "Security group for ${local.project_name} ${local.env} RDS"
  vpc_id      = aws_vpc.main.id

  ingress {
    from_port       = 5432
    to_port         = 5432
    protocol        = "tcp"
    security_groups = [aws_security_group.lambda.id]
  }

  tags = merge(
    local.common_tags,
    {
      Name = "${local.project_name}-${local.env}-rds-sg"
    }
  )
}

resource "aws_security_group" "blockchain" {
  name_prefix = "${local.project_name}-${local.env}-blockchain-"
  description = "Security group for ${local.project_name} ${local.env} blockchain node"
  vpc_id      = aws_vpc.main.id

  ingress {
    from_port = 9944
    to_port   = 9944
    protocol  = "tcp"
    cidr_blocks = [
      aws_vpc.main.cidr_block
    ]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = merge(
    local.common_tags,
    {
      Name = "${local.project_name}-${local.env}-blockchain-sg"
    }
  )
}

resource "aws_security_group" "efs_mount" {
  name_prefix = "${local.project_name}-${local.env}-efs-mount-"
  description = "Security group for EFS mount targets"
  vpc_id      = aws_vpc.main.id

  ingress {
    from_port       = 2049
    to_port         = 2049
    protocol        = "tcp"
    security_groups = [aws_security_group.lambda.id]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = merge(
    local.common_tags,
    {
      Name = "${local.project_name}-${local.env}-efs-mount-sg"
    }
  )
}

resource "aws_cloudwatch_log_group" "lambda_acceso" {
  name              = "/aws/lambda/${local.project_name}-${local.env}-acceso"
  retention_in_days = 30
  tags              = merge(local.common_tags, { Name = "${local.project_name}-${local.env}-acceso-logs" })
}

resource "aws_cloudwatch_log_stream" "lambda_acceso" {
  name           = "${local.project_name}-${local.env}-acceso-stream"
  log_group_name = aws_cloudwatch_log_group.lambda_acceso.name
}

resource "aws_cloudwatch_log_group" "lambda_despachador" {
  name              = "/aws/lambda/${local.project_name}-${local.env}-despachador"
  retention_in_days = 30
  tags              = merge(local.common_tags, { Name = "${local.project_name}-${local.env}-despachador-logs" })
}

resource "aws_cloudwatch_log_stream" "lambda_despachador" {
  name           = "${local.project_name}-${local.env}-despachador-stream"
  log_group_name = aws_cloudwatch_log_group.lambda_despachador.name
}

resource "aws_cloudwatch_log_group" "lambda_procesador" {
  name              = "/aws/lambda/${local.project_name}-${local.env}-procesador"
  retention_in_days = 30
  tags              = merge(local.common_tags, { Name = "${local.project_name}-${local.env}-procesador-logs" })
}

resource "aws_cloudwatch_log_stream" "lambda_procesador" {
  name           = "${local.project_name}-${local.env}-procesador-stream"
  log_group_name = aws_cloudwatch_log_group.lambda_procesador.name
}
