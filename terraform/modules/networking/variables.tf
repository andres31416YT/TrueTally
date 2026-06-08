variable "project_name" { type = string }
variable "env"            { type = string }
variable "vpc_cidr"       { type = string }
variable "azs"            { type = list(string) }

locals {
  name_prefix = "${var.project_name}-${var.env}"
}