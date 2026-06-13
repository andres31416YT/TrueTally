variable "project_name" { type = string }
variable "env" { type = string }
variable "vpc_cidr" { type = string }
variable "azs" { type = list(string) }

locals {
  name_prefix = "${var.project_name}-${var.env}"
}

# === 03-vpc.tf ===
# VPC Principal
resource "aws_vpc" "main" {
  cidr_block           = var.vpc_cidr
  enable_dns_support   = true
  enable_dns_hostnames = true

  tags = {
    Name = "${local.name_prefix}-vpc"
  }
}

# Internet Gateway
resource "aws_internet_gateway" "main" {
  vpc_id = aws_vpc.main.id

  tags = {
    Name = "${local.name_prefix}-igw"
  }
}

# Public Subnets (para ALB y NAT Gateway)
resource "aws_subnet" "public" {
  for_each = toset(var.azs)

  vpc_id                  = aws_vpc.main.id
  cidr_block              = cidrsubnet(var.vpc_cidr, 8, index(var.azs, each.key) * 2)
  availability_zone       = each.key
  map_public_ip_on_launch = true

  tags = {
    Name = "${local.name_prefix}-public-${each.key}"
    Tier = "public"
  }
}

# Private Subnets - Compute (para Lambdas)
resource "aws_subnet" "compute" {
  for_each = toset(var.azs)

  vpc_id            = aws_vpc.main.id
  cidr_block        = cidrsubnet(var.vpc_cidr, 8, index(var.azs, each.key) * 2 + 10)
  availability_zone = each.key

  tags = {
    Name = "${local.name_prefix}-compute-${each.key}"
    Tier = "compute"
  }
}

# Private Subnets - Database (para Aurora/RDS)
resource "aws_subnet" "database" {
  for_each = toset(var.azs)

  vpc_id            = aws_vpc.main.id
  cidr_block        = cidrsubnet(var.vpc_cidr, 8, index(var.azs, each.key) * 2 + 20)
  availability_zone = each.key

  tags = {
    Name = "${local.name_prefix}-database-${each.key}"
    Tier = "database"
  }
}

# Private Subnets - Blockchain (para ECS Fargate)
resource "aws_subnet" "blockchain" {
  for_each = toset(var.azs)

  vpc_id            = aws_vpc.main.id
  cidr_block        = cidrsubnet(var.vpc_cidr, 8, index(var.azs, each.key) * 2 + 30)
  availability_zone = each.key

  tags = {
    Name = "${local.name_prefix}-blockchain-${each.key}"
    Tier = "blockchain"
  }
}

# Elastic IPs para NAT Gateways
resource "aws_eip" "nat" {
  for_each = toset(var.azs)

  domain = "vpc"

  tags = {
    Name = "${local.name_prefix}-nat-eip-${each.key}"
  }

  depends_on = [aws_internet_gateway.main]
}

# NAT Gateways (uno por AZ)
resource "aws_nat_gateway" "main" {
  for_each = toset(var.azs)

  allocation_id = aws_eip.nat[each.key].id
  subnet_id     = aws_subnet.public[each.key].id

  tags = {
    Name = "${local.name_prefix}-nat-${each.key}"
  }

  depends_on = [aws_internet_gateway.main]
}

# Public Route Table
resource "aws_route_table" "public" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.main.id
  }

  tags = {
    Name = "${local.name_prefix}-public-rt"
  }
}

# Private Route Tables (por AZ)
resource "aws_route_table" "private" {
  for_each = toset(var.azs)

  vpc_id = aws_vpc.main.id

  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.main[each.key].id
  }

  tags = {
    Name = "${local.name_prefix}-private-rt-${each.key}"
  }
}

# Route Table Associations - Public
resource "aws_route_table_association" "public" {
  for_each = aws_subnet.public

  subnet_id      = each.value.id
  route_table_id = aws_route_table.public.id
}

# Route Table Associations - Private (compute, database, blockchain)
resource "aws_route_table_association" "compute" {
  for_each = aws_subnet.compute

  subnet_id      = each.value.id
  route_table_id = aws_route_table.private[each.key].id
}

resource "aws_route_table_association" "database" {
  for_each = aws_subnet.database

  subnet_id      = each.value.id
  route_table_id = aws_route_table.private[each.key].id
}

resource "aws_route_table_association" "blockchain" {
  for_each = aws_subnet.blockchain

  subnet_id      = each.value.id
  route_table_id = aws_route_table.private[each.key].id
}

# VPC Endpoints para servicios AWS (sin NAT Gateway)
resource "aws_vpc_endpoint" "s3" {
  vpc_id       = aws_vpc.main.id
  service_name = "com.amazonaws.us-east-1.s3"

  tags = {
    Name = "${local.name_prefix}-s3-endpoint"
  }
}

resource "aws_vpc_endpoint" "secretsmanager" {
  vpc_id              = aws_vpc.main.id
  service_name        = "com.amazonaws.us-east-1.secretsmanager"
  vpc_endpoint_type   = "Interface"
  subnet_ids          = [for s in aws_subnet.compute : s.id]
  security_group_ids  = [aws_security_group.vpc_endpoints.id]
  private_dns_enabled = true

  tags = {
    Name = "${local.name_prefix}-secretsmanager-endpoint"
  }
}

resource "aws_vpc_endpoint" "sqs" {
  vpc_id              = aws_vpc.main.id
  service_name        = "com.amazonaws.us-east-1.sqs"
  vpc_endpoint_type   = "Interface"
  subnet_ids          = [for s in aws_subnet.compute : s.id]
  security_group_ids  = [aws_security_group.vpc_endpoints.id]
  private_dns_enabled = true

  tags = {
    Name = "${local.name_prefix}-sqs-endpoint"
  }
}

# Security Groups
resource "aws_security_group" "vpc_endpoints" {
  name        = "${local.name_prefix}-vpc-endpoints-sg"
  description = "Security group for VPC endpoints"
  vpc_id      = aws_vpc.main.id

  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = [var.vpc_cidr]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# Security Group para ALB
resource "aws_security_group" "alb" {
  name        = "${local.name_prefix}-alb-sg"
  description = "Security group for Application Load Balancer"
  vpc_id      = aws_vpc.main.id

  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = [var.vpc_cidr]
  }
}

# Security Group para Lambda Functions
resource "aws_security_group" "lambda" {
  name        = "${local.name_prefix}-lambda-sg"
  description = "Security group for Lambda functions"
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

# Security Group para ECS / Blockchain
resource "aws_security_group" "ecs" {
  name        = "${local.name_prefix}-ecs-sg"
  description = "Security group for ECS blockchain tasks"
  vpc_id      = aws_vpc.main.id

  ingress {
    from_port       = 9944
    to_port         = 9944
    protocol        = "tcp"
    security_groups = [aws_security_group.lambda.id]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "${local.name_prefix}-ecs-sg"
  }
}

# Security Group para Aurora
resource "aws_security_group" "database" {
  name        = "${local.name_prefix}-database-sg"
  description = "Security group for Aurora database"
  vpc_id      = aws_vpc.main.id

  ingress {
    from_port       = 5432
    to_port         = 5432
    protocol        = "tcp"
    security_groups = [aws_security_group.lambda.id, aws_security_group.ecs.id]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "${local.name_prefix}-database-sg"
  }
}

# Security Group para ElastiCache Redis
resource "aws_security_group" "elasticache" {
  name        = "${local.name_prefix}-elasticache-sg"
  description = "Security group for ElastiCache Redis"
  vpc_id      = aws_vpc.main.id

  ingress {
    from_port       = 6379
    to_port         = 6379
    protocol        = "tcp"
    security_groups = [aws_security_group.lambda.id, aws_security_group.ecs.id]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "${local.name_prefix}-elasticache-sg"
  }
}
output "vpc_id" {
  value = aws_vpc.main.id
}

output "public_subnet_ids" {
  value = [for s in aws_subnet.public : s.id]
}

output "compute_subnet_ids" {
  value = [for s in aws_subnet.compute : s.id]
}

output "private_subnet_ids" {
  value = [for s in aws_subnet.compute : s.id]
}

output "database_subnet_ids" {
  value = [for s in aws_subnet.database : s.id]
}

output "blockchain_subnet_ids" {
  value = [for s in aws_subnet.blockchain : s.id]
}

output "public_route_table" {
  value = aws_route_table.public.id
}

output "private_route_tables" {
  value = { for k, v in aws_route_table.private : k => v.id }
}

output "lambda_security_group_id" {
  value = aws_security_group.lambda.id
}

output "lambda_sg_arn" {
  value = aws_security_group.lambda.arn
}
