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