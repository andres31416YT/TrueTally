locals {
  name_prefix = "${var.project_name}-${var.env}"
}

resource "aws_elasticache_subnet_group" "main" {
  name       = "${local.name_prefix}-elasticache-subnet-group"
  subnet_ids = var.private_subnet_ids

  lifecycle {
    ignore_changes = all # Luego de crearlo, ignora cualquier cambio futuro
  }
}

resource "aws_security_group" "elasticache" {
  name_prefix = "${local.name_prefix}-elasticache-"
  description = "Allow Redis access from Lambda"
  vpc_id      = var.vpc_id

  ingress {
    from_port       = 6379
    to_port         = 6379
    protocol        = "tcp"
    security_groups = [var.lambda_security_group_id]
    description     = "Allow Redis access from Lambda"
  }

  tags = {
    Name = "${local.name_prefix}-elasticache-sg"
  }
}

resource "aws_elasticache_replication_group" "main" {
  replication_group_id       = "${local.name_prefix}-redis"
  description                = "Redis cache"
  engine                     = "redis"
  engine_version             = "7.1"
  node_type                  = "cache.t3.micro"
  port                       = 6379
  num_cache_clusters         = 1
  automatic_failover_enabled = false
  multi_az_enabled           = false
  subnet_group_name          = aws_elasticache_subnet_group.main.name
  security_group_ids         = [aws_security_group.elasticache.id]

  at_rest_encryption_enabled = true
  kms_key_id                 = var.kms_key_arn

  tags = {
    Name = "${local.name_prefix}-redis"
  }
}

resource "aws_db_subnet_group" "main" {
  name       = "${local.name_prefix}-db-subnet-group"
  subnet_ids = var.private_subnet_ids

  lifecycle {
    ignore_changes = all
  }

  tags = {
    Name = "${local.name_prefix}-db-subnet-group"
  }
}

resource "aws_db_instance" "main" {
  identifier          = "${local.name_prefix}-postgres"
  engine              = "postgres"
  engine_version      = "15.7"
  instance_class      = "db.t3.micro"
  allocated_storage   = 20
  storage_encrypted   = true
  kms_key_id          = var.kms_key_arn
  username            = var.db_username
  password            = var.db_password
  db_name             = "truetally"
  skip_final_snapshot = var.skip_final_snapshot

  final_snapshot_identifier = var.skip_final_snapshot ? null : "${local.name_prefix}-postgres-final"

  vpc_security_group_ids = [var.database_sg_id]
  db_subnet_group_name   = aws_db_subnet_group.main.name
  multi_az               = true

  tags = {
    Name = "${local.name_prefix}-postgres"
  }
}

output "rds_endpoint" {
  value = aws_db_instance.main.endpoint
}

output "rds_proxy_endpoint" {
  value = ""
}

output "elasticache_address" {
  value = aws_elasticache_replication_group.main.primary_endpoint_address
}

output "elasticache_port" {
  value = aws_elasticache_replication_group.main.port
}

output "redis_endpoint" {
  value = aws_elasticache_replication_group.main.primary_endpoint_address
}

output "redis_port" {
  value = aws_elasticache_replication_group.main.port
}
