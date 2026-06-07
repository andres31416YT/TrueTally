variable "project_name" {
  type    = string
  default = "truetally"
}

variable "environment" {
  type    = string
  default = "dev"
}

variable "domain_name" {
  type    = string
  default = ""
}

variable "ssl_certificate_arn" {
  type    = string
  default = ""
}

variable "route53_zone_id" {
  type    = string
  default = ""
}

locals {
  name_prefix = "${var.project_name}-${var.environment}"
  use_custom_domain = var.domain_name != ""
}