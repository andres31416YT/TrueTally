resource "aws_vpc" "main" {
  cidr_block           = local.vpc_cidr
  enable_dns_hostnames = true
  enable_dns_support   = true

  tags = {
    Name        = "${local.project_name}-${local.env}-vpc"
    Project     = local.project_name
    Environment = local.env
  }
}

resource "aws_subnet" "public" {
  for_each = { for idx, az in local.azs : az => idx }

  vpc_id                  = aws_vpc.main.id
  cidr_block              = cidrsubnet(local.vpc_cidr, 4, each.value)
  availability_zone       = each.key
  map_public_ip_on_launch = true

  tags = {
    Name        = "${local.project_name}-${local.env}-public-subnet-${each.key}"
    Project     = local.project_name
    Environment = local.env
  }
}

resource "aws_subnet" "private" {
  for_each = { for idx, az in local.azs : az => idx }

  vpc_id            = aws_vpc.main.id
  cidr_block        = cidrsubnet(local.vpc_cidr, 4, each.value + 2)
  availability_zone = each.key

  tags = {
    Name        = "${local.project_name}-${local.env}-private-subnet-${each.key}"
    Project     = local.project_name
    Environment = local.env
  }
}

resource "aws_subnet" "database" {
  for_each = { for idx, az in local.azs : az => idx }

  vpc_id            = aws_vpc.main.id
  cidr_block        = cidrsubnet(local.vpc_cidr, 4, each.value + 4)
  availability_zone = each.key

  tags = {
    Name        = "${local.project_name}-${local.env}-database-subnet-${each.key}"
    Project     = local.project_name
    Environment = local.env
  }
}

resource "aws_internet_gateway" "main" {
  vpc_id = aws_vpc.main.id

  tags = {
    Name        = "${local.project_name}-${local.env}-igw"
    Project     = local.project_name
    Environment = local.env
  }
}

resource "aws_eip" "nat" {
  for_each = toset(local.azs)

  domain = "vpc"

  tags = {
    Name        = "${local.project_name}-${local.env}-nat-eip-${each.key}"
    Project     = local.project_name
    Environment = local.env
  }

  depends_on = [aws_internet_gateway.main]
}

resource "aws_nat_gateway" "main" {
  for_each = { for idx, az in local.azs : az => idx }

  allocation_id = aws_eip.nat[each.key].id
  subnet_id     = aws_subnet.public[each.key].id

  tags = {
    Name        = "${local.project_name}-${local.env}-nat-${each.key}"
    Project     = local.project_name
    Environment = local.env
  }

  depends_on = [aws_internet_gateway.main]
}

resource "aws_route_table" "public" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.main.id
  }

  tags = {
    Name        = "${local.project_name}-${local.env}-public-rt"
    Project     = local.project_name
    Environment = local.env
  }
}

resource "aws_route_table" "private" {
  for_each = { for idx, az in local.azs : az => idx }

  vpc_id = aws_vpc.main.id

  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.main[each.key].id
  }

  tags = {
    Name        = "${local.project_name}-${local.env}-private-rt-${each.key}"
    Project     = local.project_name
    Environment = local.env
  }
}

resource "aws_route_table_association" "public" {
  for_each = aws_subnet.public

  subnet_id      = each.value.id
  route_table_id = aws_route_table.public.id
}

resource "aws_route_table_association" "private" {
  for_each = aws_subnet.private

  subnet_id      = each.value.id
  route_table_id = aws_route_table.private[each.key].id
}

