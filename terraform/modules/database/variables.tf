variable "project_name" { type = string }
variable "environment" { type = string }
variable "db_username" { type = string }
variable "db_password" { type = string }
variable "vpc_cidr" { type = string }
variable "azs" { type = list(string) }
locals {
  name_prefix = "${var.project_name}-${var.environment}"
}
