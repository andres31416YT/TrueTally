# Secrets Manager - Lambda Config
resource "aws_secretsmanager_secret" "lambda_api_url" {
  name        = "${local.name_prefix}/lambda/api-url"
  description = "API URL configuration for lambdas"
  kms_key_id  = aws_kms_key.main.arn
}

resource "aws_secretsmanager_secret_version" "lambda_api_url" {
  secret_id = aws_secretsmanager_secret.lambda_api_url.id
  secret_string = jsonencode({
    api_url     = "" # Set after API Gateway deployment
    stage       = terraform.workspace
    environment = terraform.workspace
  })
}

resource "aws_secretsmanager_secret" "lambda_sqs_url" {
  name        = "${local.name_prefix}/lambda/sqs-url"
  description = "SQS queue URL for lambda-despachador"
  kms_key_id  = aws_kms_key.main.arn
}

resource "aws_secretsmanager_secret_version" "lambda_sqs_url" {
  secret_id = aws_secretsmanager_secret.lambda_sqs_url.id
  secret_string = jsonencode({
    vote_queue_url = aws_sqs_queue.vote_queue.id
  })
}