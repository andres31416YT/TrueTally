variable "project_name" { type = string }
variable "environment" { type = string }
locals {
  name_prefix = "${var.project_name}-${var.environment}"
}
