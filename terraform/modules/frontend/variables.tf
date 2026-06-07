variable "project_name"        { type = string }
variable "env"                 { type = string }
variable "domain_name"         { type = string }
variable "ssl_certificate_arn" { type = string }
variable "route53_zone_id"     { type = string }

locals {
  name_prefix    = "${var.project_name}-${var.env}"
  use_custom_domain = var.domain_name != ""
}