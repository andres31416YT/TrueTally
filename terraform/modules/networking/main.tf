locals {
  name_prefix = "${var.project_name}-${var.env}"
}

resource "aws_vpc" "main" {
  cidr_block           = var.vpc_cidr
  enable_dns_support   = true
  enable_dns_hostnames = true
  tags                 = { Name = "${local.name_prefix}-vpc" }
}

resource "aws_cloudwatch_log_group" "vpc_flow_log" {
  name              = "${local.name_prefix}-vpc-flow-logs"
  retention_in_days = 7
  kms_key_id        = var.kms_key_arn
}

resource "aws_flow_log" "main" {
  vpc_id          = aws_vpc.main.id
  iam_role_arn    = aws_iam_role.vpc_flow_log.arn
  log_destination = aws_cloudwatch_log_group.vpc_flow_log.arn
  traffic_type    = "ALL"
}

resource "aws_iam_role" "vpc_flow_log" {
  name = "${local.name_prefix}-vpc-flow-log-role"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action    = "sts:AssumeRole"
      Effect    = "Allow"
      Principal = { Service = "vpc-flow-logs.amazonaws.com" }
    }]
  })
}

resource "aws_iam_role_policy" "vpc_flow_log" {
  name = "${local.name_prefix}-vpc-flow-log-policy"
  role = aws_iam_role.vpc_flow_log.id
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect = "Allow"
      Action = [
        "logs:CreateLogStream",
        "logs:PutLogEvents"
      ]
      Resource = "${aws_cloudwatch_log_group.vpc_flow_log.arn}:*"
    }]
  })
}

resource "aws_internet_gateway" "main" {
  vpc_id = aws_vpc.main.id
  tags   = { Name = "${local.name_prefix}-igw" }
}

resource "aws_eip" "nat" {
  for_each = toset(var.azs)
  domain   = "vpc"
  tags     = { Name = "${local.name_prefix}-nat-eip-${each.key}" }
}

resource "aws_nat_gateway" "nat" {
  for_each      = toset(var.azs)
  allocation_id = aws_eip.nat[each.key].id
  subnet_id     = aws_subnet.public[each.key].id
  tags          = { Name = "${local.name_prefix}-nat-${each.key}" }
}

resource "aws_subnet" "public" {
  for_each                = toset(var.azs)
  vpc_id                  = aws_vpc.main.id
  cidr_block              = cidrsubnet(var.vpc_cidr, 8, index(var.azs, each.key) * 2)
  availability_zone       = each.key
  map_public_ip_on_launch = true
  tags                    = { Name = "${local.name_prefix}-public-${each.key}" }
}

resource "aws_subnet" "compute" {
  for_each          = toset(var.azs)
  vpc_id            = aws_vpc.main.id
  cidr_block        = cidrsubnet(var.vpc_cidr, 8, index(var.azs, each.key) * 2 + 10)
  availability_zone = each.key
  tags              = { Name = "${local.name_prefix}-compute-${each.key}" }
}

resource "aws_subnet" "database" {
  for_each          = toset(var.azs)
  vpc_id            = aws_vpc.main.id
  cidr_block        = cidrsubnet(var.vpc_cidr, 8, index(var.azs, each.key) * 2 + 20)
  availability_zone = each.key
  tags              = { Name = "${local.name_prefix}-database-${each.key}" }
}

resource "aws_subnet" "blockchain" {
  for_each          = toset(var.azs)
  vpc_id            = aws_vpc.main.id
  cidr_block        = cidrsubnet(var.vpc_cidr, 8, index(var.azs, each.key) * 2 + 30)
  availability_zone = each.key
  tags              = { Name = "${local.name_prefix}-blockchain-${each.key}" }
}

resource "aws_route_table" "public" {
  vpc_id = aws_vpc.main.id
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.main.id
  }
  tags = { Name = "${local.name_prefix}-public-rt" }

  lifecycle {
    ignore_changes = all
  }
}

resource "aws_route_table_association" "public" {
  for_each       = toset(var.azs)
  subnet_id      = aws_subnet.public[each.key].id
  route_table_id = aws_route_table.public.id
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
    description = "Allow all outbound traffic"
  }

  tags = { Name = "${local.name_prefix}-lambda-sg" }
}

resource "aws_security_group_rule" "lambda_to_rds" {
  description                     = "Allow Lambda to connect to RDS PostgreSQL"
  type                            = "ingress"
  from_port                       = 5432
  to_port                         = 5432
  protocol                        = "tcp"
  security_group_id               = aws_security_group.lambda.id
  source_security_group_id        = aws_security_group.lambda.id
}

resource "aws_security_group" "database" {
  name        = "${local.name_prefix}-database-sg"
  description = "Security group for PostgreSQL (RDS)"
  vpc_id      = aws_vpc.main.id
  ingress {
    from_port       = 5432
    to_port         = 5432
    protocol        = "tcp"
    security_groups = [aws_security_group.lambda.id]
    description     = "Allow PostgreSQL access from Lambda"
  }
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
    description = "Allow all outbound traffic"
  }
  tags = { Name = "${local.name_prefix}-database-sg" }
}

resource "aws_security_group" "blockchain" {
  name        = "${local.name_prefix}-blockchain-sg"
  description = "Security group for blockchain ECS nodes"
  vpc_id      = aws_vpc.main.id

  ingress {
    from_port = 9944
    to_port   = 9944
    protocol  = "tcp"
    self      = true
    description = "Allow blockchain node communication"
  }

  ingress {
    from_port = 2049
    to_port   = 2049
    protocol  = "tcp"
    self      = true
    description = "Allow NFS communication for blockchain"
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
    description = "Allow all outbound traffic"
  }

  tags = {
    Name = "${local.name_prefix}-blockchain-sg"
  }
}

output "vpc_id" { value = aws_vpc.main.id }
output "public_subnet_ids" { value = [for s in aws_subnet.public : s.id] }
output "compute_subnet_ids" { value = [for s in aws_subnet.compute : s.id] }
output "private_subnet_ids" { value = concat([for s in aws_subnet.compute : s.id], [for s in aws_subnet.database : s.id]) }
output "database_subnet_ids" { value = [for s in aws_subnet.database : s.id] }
output "blockchain_subnet_ids" { value = [for s in aws_subnet.blockchain : s.id] }
output "lambda_security_group_id" { value = aws_security_group.lambda.id }
output "lambda_sg_arn" { value = aws_security_group.lambda.arn }
output "database_sg_id" { value = aws_security_group.database.id }
output "blockchain_sg_id" { value = aws_security_group.blockchain.id }

# VPC Endpoints
resource "aws_vpc_endpoint" "s3" {
  vpc_id            = aws_vpc.main.id
  service_name      = "com.amazonaws.${var.aws_region}.s3"
  vpc_endpoint_type = "Gateway"
  route_table_ids   = [aws_route_table.public.id]

  tags = { Name = "${local.name_prefix}-s3-endpoint" }
}

resource "aws_vpc_endpoint" "secretsmanager" {
  vpc_id              = aws_vpc.main.id
  service_name        = "com.amazonaws.${var.aws_region}.secretsmanager"
  vpc_endpoint_type   = "Interface"
  subnet_ids          = [for s in aws_subnet.compute : s.id]
  security_group_ids  = [aws_security_group.lambda.id]
  private_dns_enabled = true

  tags = { Name = "${local.name_prefix}-secretsmanager-endpoint" }
}

resource "aws_vpc_endpoint" "sqs" {
  vpc_id              = aws_vpc.main.id
  service_name        = "com.amazonaws.${var.aws_region}.sqs"
  vpc_endpoint_type   = "Interface"
  subnet_ids          = [for s in aws_subnet.compute : s.id]
  security_group_ids  = [aws_security_group.lambda.id]
  private_dns_enabled = true

  tags = { Name = "${local.name_prefix}-sqs-endpoint" }
}

resource "aws_vpc_endpoint" "ecr_api" {
  vpc_id              = aws_vpc.main.id
  service_name        = "com.amazonaws.${var.aws_region}.ecr.api"
  vpc_endpoint_type   = "Interface"
  subnet_ids          = [for s in aws_subnet.blockchain : s.id]
  security_group_ids  = [aws_security_group.lambda.id]
  private_dns_enabled = false

  tags = { Name = "${local.name_prefix}-ecr-api-endpoint" }
}

resource "aws_vpc_endpoint" "ecr_dkr" {
  vpc_id              = aws_vpc.main.id
  service_name        = "com.amazonaws.${var.aws_region}.ecr.dkr"
  vpc_endpoint_type   = "Interface"
  subnet_ids          = [for s in aws_subnet.blockchain : s.id]
  security_group_ids  = [aws_security_group.lambda.id]
  private_dns_enabled = false

  tags = { Name = "${local.name_prefix}-ecr-dkr-endpoint" }
}
