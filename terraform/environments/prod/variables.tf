variable "aws_region" {
  type    = string
  default = "us-east-1"
}

variable "project_name" {
  type    = string
  default = "truetally"
}

variable "environment" {
  type    = string
  default = "prod"
}

variable "vpc_cidr" {
  type    = string
  default = "10.1.0.0/16"
}

variable "azs" {
  type    = list(string)
  default = ["us-east-1a", "us-east-1b"]
}

variable "db_username" {
  type      = string
  default   = "truetally"
  sensitive = true
}

variable "db_password" {
  type      = string
  sensitive = true
}

variable "lambda_node_url_az1" {
  type    = string
  default = "http://truetally-prod-blockchain-alb-1.elb.us-east-1.amazonaws.com"
}

variable "lambda_node_url_az2" {
  type    = string
  default = "http://truetally-prod-blockchain-alb-2.elb.us-east-1.amazonaws.com"
}

variable "domain_name" {
  type    = string
  default = "app.truetally.com"
}

variable "ssl_certificate_arn" {
  type    = string
  default = "arn:aws:acm:us-east-1:123456789:certificate/xxxxx"
}

variable "route53_zone_id" {
  type    = string
  default = "Z1234567890ABC"
}
