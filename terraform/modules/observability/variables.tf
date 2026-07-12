variable "project_name" {
  type = string
}

variable "env" {
  type = string
}

variable "vpc_id" {
  type = string
}

variable "subnet_ids" {
  type = list(string)
}

variable "kms_key_arn" {
  type = string
}

variable "aws_region" {
  type    = string
  default = "us-east-1"
}

variable "blockchain_sg_id" {
  type    = string
  default = ""
}
