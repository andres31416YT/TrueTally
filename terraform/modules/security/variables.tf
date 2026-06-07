variable "project_name" {
  type    = string
  default = "truetally"
}

variable "env" {
  type    = string
  default = "dev"
}

variable "db_password" {
  type      = string
  sensitive = true
}

locals {
  name_prefix = "${var.project_name}-${var.env}"
}