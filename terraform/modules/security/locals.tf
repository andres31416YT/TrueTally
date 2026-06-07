variable "project_name" {
  type    = string
  default = "truetally"
}

variable "environment" {
  type    = string
  default = "dev"
}

locals {
  name_prefix = "${var.project_name}-${var.environment}"
}