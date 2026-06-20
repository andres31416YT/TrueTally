variable "project_name" {
  type    = string
  default = "truetally"
}

variable "environment" {
  type    = string
  default = "dev"
}

variable "vpc_cidr" {
  type    = string
  default = "10.0.0.0/16"
}

variable "azs" {
  type    = list(string)
  default = ["us-east-1a", "us-east-1b"]
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
  type    = string
  default = "andrespaganroncall.qzz.io"
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