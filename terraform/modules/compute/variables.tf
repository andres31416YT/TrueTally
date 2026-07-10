variable "project_name" {
  type = string
}

variable "env" {
  type = string
}

variable "vpc_id" {
  type = string
}

variable "public_subnet_ids" {
  type = list(string)
}

variable "private_subnet_ids" {
  type = list(string)
}

variable "azs" {
  type = list(string)
}

variable "blockchain_subnet_ids" {
  type = list(string)
}

variable "kms_key_arn" {
  type = string
}

variable "lambda_security_group_id" {
  type = string
}

variable "blockchain_security_group_id" {
  type = string
}

variable "lambda_sg_arn" {
  type = string
}

variable "db_credentials_secret_arn" {
  type = string
}

variable "redis_auth_token_secret_arn" {
  type = string
}

variable "vote_queue_arn" {
  type = string
}

variable "vote_queue_url" {
  type = string
}

variable "aws_region" {
  type    = string
  default = "us-east-1"
}

variable "ecr_repository_url" {
  type = string
}

variable "lambda_zip_path" {
  type        = string
  description = "Path to lambda ZIP artifacts directory"
}

variable "dlq_arn" {
  type = string
}

variable "lambda_reserved_concurrent_executions" {
  type    = number
  default = null
}
