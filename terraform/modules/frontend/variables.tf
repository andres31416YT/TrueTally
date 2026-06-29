variable "project_name" {
  type = string
}

variable "env" {
  type = string
}

variable "aws_region" {
  type = string
}

variable "domain_name" {
  type = string
}

variable "ssl_certificate_arn" {
  type = string
}

variable "create_acm_certificate" {
  type    = bool
  default = false
}

variable "route53_zone_id" {
  type    = string
  default = ""
}

variable "enabled" {
  type    = bool
  default = true
}

variable "kms_key_arn" {
  type = string
}

variable "bucket_suffix" {
  type    = string
  default = ""
}
