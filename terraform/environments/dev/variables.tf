variable "project_name" {
  type = string
}

variable "environment" {
  type = string
}

variable "vpc_cidr" {
  type = string
}

variable "azs" {
  type = list(string)
}

variable "db_password" {
  type      = string
  sensitive = true
}

variable "redis_auth_token" {
  type      = string
  sensitive = true
}

variable "lambda_node_url_az1" {
  type    = string
  default = "http://localhost:9944"
}

variable "lambda_node_url_az2" {
  type    = string
  default = "http://localhost:9944"
}

variable "domain_name" {
  type = string
}

variable "create_acm_certificate" {
  type    = bool
  default = false
}

variable "ssl_certificate_arn" {
  type    = string
  default = ""
}

variable "route53_zone_id" {
  type    = string
  default = ""
}

variable "aws_region" {
  type    = string
  default = "us-east-1"
}

variable "aws_account_id" {
  type    = string
  default = ""
}

variable "lambda_zip_path" {
  type        = string
  default     = "terraform/artifacts"
  description = "Path to lambda ZIP artifacts directory"
}