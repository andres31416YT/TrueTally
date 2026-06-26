variable "project_name" {
  type = string
}

variable "env" {
  type = string
}

variable "db_username" {
  type = string
}

variable "skip_final_snapshot" {
  type    = bool
  default = true
}

variable "db_password" {
  type      = string
  sensitive = true
}

variable "redis_auth_token" {
  type      = string
  sensitive = true
}

variable "vpc_id" {
  type = string
}

variable "private_subnet_ids" {
  type = list(string)
}

variable "kms_key_arn" {
  type = string
}

variable "lambda_security_group_id" {
  type = string
}

variable "database_sg_id" {
  type = string
}

variable "db_credentials_secret_arn" {
  type = string
}

variable "redis_auth_token_secret_arn" {
  type = string
}
