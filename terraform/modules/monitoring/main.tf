variable "project_name" { type = string }
variable "env" { type = string }

locals {
  name_prefix = "${var.project_name}-${var.env}"
}

# CloudWatch Log Groups
resource "aws_cloudwatch_log_group" "lambda_acceso" {
  name              = "/aws/lambda/${local.name_prefix}-acceso"
  retention_in_days = 7

  tags = {
    Environment = var.env
  }
}

resource "aws_cloudwatch_log_group" "lambda_despachador" {
  name              = "/aws/lambda/${local.name_prefix}-despachador"
  retention_in_days = 7

  tags = {
    Environment = var.env
  }
}

resource "aws_cloudwatch_log_group" "lambda_procesador" {
  name              = "/aws/lambda/${local.name_prefix}-procesador"
  retention_in_days = 7

  tags = {
    Environment = var.env
  }
}

resource "aws_cloudwatch_log_group" "ecs_blockchain" {
  name              = "/ecs/${local.name_prefix}-blockchain"
  retention_in_days = 7

  tags = {
    Environment = var.env
  }
}

output "log_group_acceso" {
  value = aws_cloudwatch_log_group.lambda_acceso.name
}

output "log_group_despachador" {
  value = aws_cloudwatch_log_group.lambda_despachador.name
}

output "log_group_procesador" {
  value = aws_cloudwatch_log_group.lambda_procesador.name
}