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
variable "aws_region" {
  type    = string
  default = "us-east-1"
}

locals {
  name_prefix = "${var.project_name}-${var.env}"
}

output "sqs_queue_url" {
  value = var.sqs_queue_url
}

output "rds_proxy_endpoint" {
  value = var.rds_proxy_endpoint
}

output "rds_endpoint" {
  value = var.rds_endpoint
}

output "redis_endpoint" {
  value = var.redis_endpoint
}

output "redis_port" {
  value = var.redis_port
}

output "lambda_node_url_az1" {
  value = var.lambda_node_url_az1
}

output "lambda_node_url_az2" {
  value = var.lambda_node_url_az2
}
