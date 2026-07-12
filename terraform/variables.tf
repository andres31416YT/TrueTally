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
  default   = null
  sensitive = true
  type      = string
}

variable "redis_auth_token" {
  default   = null
  sensitive = true
  type      = string
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
