variable "project_name" {
  default = "truetally"
  type    = string
}

variable "environment" {
  default = "dev"
  type    = string
}

variable "vpc_cidr" {
  default = "10.0.0.0/16"
  type    = string
}

variable "azs" {
  default = ["us-east-1a", "us-east-1b"]
  type    = list(string)
}

variable "db_password" {
  sensitive = true
  type      = string
}

variable "redis_auth_token" {
  sensitive = true
  type      = string
}

variable "lambda_node_url_az1" {
  default = "http://localhost:9944"
  type    = string
}

variable "lambda_node_url_az2" {
  default = "http://localhost:9944"
  type    = string
}

variable "domain_name" {
  default = ""
  type    = string
}

variable "ssl_certificate_arn" {
  default = ""
  type    = string
}

variable "route53_zone_id" {
  default = ""
  type    = string
}
