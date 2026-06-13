variable "project_name" { type = string }
variable "env" { type = string }
variable "db_username" { type = string }
variable "db_password" {
  type      = string
  sensitive = true
}
variable "vpc_cidr" { type = string }
variable "azs" { type = list(string) }

locals {
  name_prefix = "${var.project_name}-${var.env}"
}

# === 04-elasticache.tf ===
# ElastiCache Redis - Sesiones y cache de lectura
resource "aws_elasticache_subnet_group" "main" {
  name       = "${local.name_prefix}-elasticache-subnet-group"
  subnet_ids = [for s in aws_subnet.database : s.id]
}

resource "random_password" "redis_auth_token" {
  length  = 32
  special = false
}

resource "aws_elasticache_replication_group" "main" {
  replication_group_id       = "${local.name_prefix}-redis"
  description                = "Redis cache for TrueTally"
  engine                     = "redis"
  engine_version             = "7.1"
  node_type                  = "cache.t3.micro"
  port                       = 6379
  parameter_group_name       = "default.redis7.cluster.on"
  num_cache_clusters         = 2
  automatic_failover_enabled = true
  multi_az_enabled           = true
  subnet_group_name          = aws_elasticache_subnet_group.main.name
  security_group_ids         = [aws_security_group.elasticache.id]
  at_rest_encryption_enabled = true
  transit_encryption_enabled = true
  auth_token                 = random_password.redis_auth_token.result
  kms_key_id                 = aws_kms_key.main.arn

  log_delivery_configuration {
    destination      = aws_cloudwatch_log_group.elasticache.name
    destination_type = "cloudwatch-logs"
    log_format       = "text"
    log_type         = "slow-log"
  }

  tags = {
    Name = "${local.name_prefix}-redis"
  }
}

resource "aws_secretsmanager_secret" "redis_auth_token" {
  name        = "${local.name_prefix}/redis/auth-token"
  description = "Redis auth token"
  kms_key_id  = aws_kms_key.main.arn
}

resource "aws_secretsmanager_secret_version" "redis_auth_token" {
  secret_id     = aws_secretsmanager_secret.redis_auth_token.id
  secret_string = random_password.redis_auth_token.result
}

resource "aws_cloudwatch_log_group" "elasticache" {
  name              = "/aws/elasticache/${local.name_prefix}-redis"
  retention_in_days = 7
}
# === 05-rds.tf ===
resource "aws_db_subnet_group" "main" {
  name       = "${local.name_prefix}-db-subnet-group"
  subnet_ids = [for s in aws_subnet.database : s.id]

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
  master_password                 = random_password.db_password.result
  db_cluster_parameter_group_name = aws_rds_cluster_parameter_group.main.name
  db_subnet_group_name            = aws_db_subnet_group.main.name
  vpc_security_group_ids          = [aws_security_group.database.id]
  storage_encrypted               = true
  kms_key_id                      = aws_kms_key.main.arn
  skip_final_snapshot             = false
  final_snapshot_identifier       = "${local.name_prefix}-aurora-final-${formatdate("YYYY-MM-DD-hhmm", timestamp())}"

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
  monitoring_interval  = 60
  monitoring_role_arn  = aws_iam_role.rds_monitoring.arn
  ca_cert_identifier   = "rds-ca-rsa2048-g1"

  tags = {
    Name = "${local.name_prefix}-aurora-instance"
  }
}

resource "aws_secretsmanager_secret" "db_credentials" {
  name        = "${local.name_prefix}/db/credentials"
  description = "Database credentials for TrueTally"
  kms_key_id  = aws_kms_key.main.arn
}

resource "aws_secretsmanager_secret_version" "db_credentials" {
  secret_id = aws_secretsmanager_secret.db_credentials.id
  secret_string = jsonencode({
    username = var.db_username
    password = random_password.db_password.result
    engine   = "postgres"
    port     = 5432
    dbname   = "truetally"
    host     = aws_rds_cluster.main.endpoint
  })

  lifecycle {
    ignore_changes = [secret_string]
  }
}
# === 06-db-proxy.tf ===
resource "aws_db_proxy" "main" {
  name                   = "${local.name_prefix}-aurora-proxy"
  debug_logging          = false
  engine_family          = "POSTGRESQL"
  idle_client_timeout    = 1800
  require_tls            = true
  role_arn               = aws_iam_role.rds_proxy.arn
  vpc_subnet_ids         = [for s in aws_subnet.database : s.id]
  vpc_security_group_ids = [aws_security_group.database.id]

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

output "elasticache_address" {
  value = aws_elasticache_replication_group.main.primary_endpoint_address
}

output "elasticache_port" {
  value = aws_elasticache_replication_group.main.port
}