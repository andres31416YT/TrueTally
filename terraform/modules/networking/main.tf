variable "project_name" { type = string }
variable "env" { type = string }
variable "vpc_cidr" { type = string }
variable "azs" { type = list(string) }

locals {
  name_prefix = "${var.project_name}-${var.env}"
}

resource "aws_vpc" "main" {
  cidr_block           = var.vpc_cidr
  enable_dns_support   = true
  enable_dns_hostnames = true

  tags = {
    Name = "${local.name_prefix}-vpc"
  }
}

resource "aws_subnet" "public" {
  for_each = toset(var.azs)
  vpc_id                  = aws_vpc.main.id
  cidr_block              = cidrsubnet(var.vpc_cidr, 8, index(var.azs, each.key) * 2)
  availability_zone       = each.key
  map_public_ip_on_launch = true

  tags = {
    Name = "${local.name_prefix}-public-${each.key}"
  }
}

resource "aws_subnet" "compute" {
  for_each = toset(var.azs)
  vpc_id            = aws_vpc.main.id
  cidr_block        = cidrsubnet(var.vpc_cidr, 8, index(var.azs, each.key) * 2 + 10)
  availability_zone = each.key

  tags = {
    Name = "${local.name_prefix}-compute-${each.key}"
  }
}

resource "aws_subnet" "database" {
  for_each = toset(var.azs)
  vpc_id            = aws_vpc.main.id
  cidr_block        = cidrsubnet(var.vpc_cidr, 8, index(var.azs, each.key) * 2 + 20)
  availability_zone = each.key

  tags = {
    Name = "${local.name_prefix}-database-${each.key}"
  }
}

resource "aws_subnet" "blockchain" {
  for_each = toset(var.azs)
  vpc_id            = aws_vpc.main.id
  cidr_block        = cidrsubnet(var.vpc_cidr, 8, index(var.azs, each.key) * 2 + 30)
  availability_zone = each.key

  tags = {
    Name = "${local.name_prefix}-blockchain-${each.key}"
  }
}

resource "aws_security_group" "lambda" {
  name        = "${local.name_prefix}-lambda-sg"
  description = "Security group for Lambda"
  vpc_id      = aws_vpc.main.id

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "${local.name_prefix}-lambda-sg"
  }
}

output "vpc_id" { value = aws_vpc.main.id }
output "public_subnet_ids" { value = [for s in aws_subnet.public : s.id] }
output "compute_subnet_ids" { value = [for s in aws_subnet.compute : s.id] }
output "private_subnet_ids" { value = [for s in aws_subnet.compute : s.id] }
output "database_subnet_ids" { value = [for s in aws_subnet.database : s.id] }
output "blockchain_subnet_ids" { value = [for s in aws_subnet.blockchain : s.id] }
output "lambda_security_group_id" { value = aws_security_group.lambda.id }
output "lambda_sg_arn" { value = aws_security_group.lambda.arn }

output "database_sg_id" {
  value = aws_security_group.database.id
}
