variable "project_name" { type = string }
variable "env" { type = string }
variable "db_username" { type = string }
variable "db_password" {
  type      = string
  sensitive = true
}
variable "redis_auth_token" {
  type      = string
  sensitive = true
}
variable "vpc_id" { type = string }
variable "private_subnet_ids" { type = list(string) }
variable "kms_key_arn" { type = string }
variable "lambda_security_group_id" { type = string }

# === 04-elasticache.tf ===
resource "aws_elasticache_subnet_group" "main" {
  name       = "${local.name_prefix}-elasticache-subnet-group"
  subnet_ids = var.private_subnet_ids
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
  }

  tags = {
    Name = "${local.name_prefix}-elasticache-sg"
  }
}

resource "aws_elasticache_replication_group" "main" {
  replication_group_id       = "${local.name_prefix}-redis"
  description                = "Redis cache for TrueTally"
  engine                     = "redis"
  engine_version             = "7.1"
  node_type                  = "cache.t3.micro"
  port                       = 6379
  parameter_group_name       = "default.redis7"
  num_cache_clusters         = 2
  automatic_failover_enabled = true
  multi_az_enabled           = true
  subnet_group_name          = aws_elasticache_subnet_group.main.name
  security_group_ids         = [aws_security_group.elasticache.id]
  at_rest_encryption_enabled = true
  transit_encryption_enabled = true
  auth_token                 = var.redis_auth_token
  kms_key_id                 = var.kms_key_arn

  tags = {
    Name = "${local.name_prefix}-redis"
  }
}

resource "aws_secretsmanager_secret" "redis_auth_token" {
  name        = "${local.name_prefix}/redis/auth-token"
  description = "Redis auth token"
  kms_key_id  = var.kms_key_arn
}

resource "aws_secretsmanager_secret_version" "redis_auth_token" {
  secret_id     = aws_secretsmanager_secret.redis_auth_token.id
  secret_string = var.redis_auth_token
}

# === 05-rds.tf ===
resource "aws_db_subnet_group" "main" {
  name       = "${local.name_prefix}-db-subnet-group"
  subnet_ids = var.private_subnet_ids

  tags = {
    Name = "${local.name_prefix}-db-subnet-group"
  }
}

resource "aws_rds_cluster_parameter_group" "main" {
  family = "aurora-postgresql15"
  name   = "${local.name_prefix}-aurora-params"

  parameter {
    name         = "log_statement"
    value        = "all"
    apply_method = "pending-reboot"
  }
}

resource "aws_rds_cluster" "main" {
  cluster_identifier              = "${local.name_prefix}-aurora"
  engine                          = "aurora-postgresql"
  engine_mode                     = "serverless"
  engine_version                  = "15.5"
  database_name                   = "truetally"
  master_username                 = var.db_username
  master_password                 = var.db_password
  db_cluster_parameter_group_name = aws_rds_cluster_parameter_group.main.name
  db_subnet_group_name            = aws_db_subnet_group.main.name
  vpc_security_group_ids          = [var.rds_security_group_id]
  storage_encrypted               = true
  kms_key_id                      = var.kms_key_arn
  skip_final_snapshot             = true

  scaling_configuration {
    auto_pause               = false
    min_capacity             = 2
    max_capacity             = 8
    timeout_action           = "RollbackCapacityChange"
    seconds_until_auto_pause = 300
  }

  tags = {
    Name = "${local.name_prefix}-aurora"
  }
}

resource "aws_rds_cluster_instance" "main" {
  identifier           = "${local.name_prefix}-aurora-instance-1"
  cluster_identifier   = aws_rds_cluster.main.id
  engine               = "aurora-postgresql"
  engine_version       = "15.5"
  instance_class       = "db.serverless"
  db_subnet_group_name = aws_db_subnet_group.main.name
  publicly_accessible  = false
  monitoring_interval  = 0

  tags = {
    Name = "${local.name_prefix}-aurora-instance"
  }
}

resource "aws_secretsmanager_secret" "db_credentials" {
  name        = "${local.name_prefix}/db/credentials"
  description = "Database credentials for TrueTally"
  kms_key_id  = var.kms_key_arn
}

resource "aws_secretsmanager_secret_version" "db_credentials" {
  secret_id     = aws_secretsmanager_secret.db_credentials.id
  secret_string = jsonencode({
    username = var.db_username
    password = var.db_password
    engine   = "postgres"
    port     = 5432
    dbname   = "truetally"
    host     = aws_rds_cluster.main.endpoint
  })
}

# === 06-db-proxy.tf ===
resource "aws_iam_role" "rds_proxy" {
  name = "${local.name_prefix}-rds-proxy-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "rds.amazonaws.com"
        }
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "rds_proxy" {
  role       = aws_iam_role.rds_proxy.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSRDSProxyServiceRolePolicy"
}

resource "aws_db_proxy" "main" {
  name                   = "${local.name_prefix}-aurora-proxy"
  debug_logging          = false
  engine_family          = "POSTGRESQL"
  idle_client_timeout    = 1800
  require_tls            = true
  role_arn               = aws_iam_role.rds_proxy.arn
  vpc_subnet_ids         = var.private_subnet_ids
  vpc_security_group_ids = [var.rds_security_group_id]

  auth {
    description = "TrueTally DB access"
    iam_auth    = false
    secret_arn  = aws_secretsmanager_secret.db_credentials.arn
    username    = var.db_username
  }

  tags = {
    Name = "${local.name_prefix}-aurora-proxy"
  }
}

output "db_instance_id" {
  value = aws_rds_cluster_instance.main.id
}

output "db_cluster_arn" {
  value = aws_rds_cluster.main.arn
}

output "rds_proxy_endpoint" {
  value = aws_db_proxy.main.endpoint
}

output "rds_endpoint" {
  value = aws_rds_cluster.main.endpoint
}

output "elasticache_address" {
  value = aws_elasticache_replication_group.main.primary_endpoint_address
}

output "elasticache_port" {
  value = aws_elasticache_replication_group.main.port
}
