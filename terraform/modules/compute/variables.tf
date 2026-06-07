variable "project_name" { type = string }
variable "environment" { type = string }
variable "lambda_node_url_az1" { type = string }
variable "lambda_node_url_az2" { type = string }
variable "vpc_cidr" { type = string }
variable "azs" { type = list(string) }
locals {
  name_prefix = "${var.project_name}-${var.environment}"
}
