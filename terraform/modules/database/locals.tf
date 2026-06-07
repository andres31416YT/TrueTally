variable "project_name" {
  type    = string
  default = "truetally"
}

variable "environment" {
  type    = string
  default = "dev"
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

locals {
  name_prefix = "${var.project_name}-${var.environment}"
}