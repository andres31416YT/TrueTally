variable "project_name" {
  type    = string
  default = "truetally"
}

variable "environment" {
  type    = string
  default = "dev"
}

variable "lambda_node_url_az1" {
  type = string
}

variable "lambda_node_url_az2" {
  type = string
}

locals {
  name_prefix = "${var.project_name}-${var.environment}"
}