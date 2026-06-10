output "kms_key_id" {
  value = aws_kms_key.main.id
}

output "kms_key_arn" {
  value = aws_kms_key.main.arn
}

output "lambda_role_arn" {
  value = aws_iam_role.lambda.arn
}

output "rds_monitoring_role_arn" {
  value = aws_iam_role.rds_monitoring.arn
}

output "rds_proxy_role_arn" {
  value = aws_iam_role.rds_proxy.arn
}

output "ecs_task_execution_role_arn" {
  value = aws_iam_role.ecs_task_execution.arn
}

output "db_credentials_secret_arn" {
  value = aws_secretsmanager_secret.db_credentials.arn
}

output "lambda_sqs_url_secret_arn" {
  value = aws_secretsmanager_secret.lambda_sqs_url.arn
}