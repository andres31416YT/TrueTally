variable "project_name" {
  default = "truetally"
  type    = string
}

variable "environment" {
  default = "prod"
  type    = string
}

variable "vpc_cidr" {
  default = "10.1.0.0/16"
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
  default = "http://truetally-prod-blockchain-alb-1.elb.us-east-1.amazonaws.com"
  type    = string
}

variable "lambda_node_url_az2" {
  default = "http://truetally-prod-blockchain-alb-2.elb.us-east-1.amazonaws.com"
  type    = string
}

variable "domain_name" {
  default = "andrespaganroncall.qzz.io"
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
