variable "project_name" { type = string }
variable "env"            { type = string }
variable "db_username"    { type = string }
variable "db_password"    {
  type      = string
  sensitive = true
}
variable "vpc_cidr"       { type = string }
variable "azs"            { type = list(string) }

locals {
  name_prefix = "${var.project_name}-${var.env}"
}