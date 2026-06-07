variable "vpc_cidr" { type = string }
variable "azs" { type = list(string) }
locals {
  name_prefix = "${var.project_name}-${var.environment}"
}
