resource "aws_db_subnet_group" "main" {
  name       = "${local.project_name}-${local.env}-db-subnet-group"
  subnet_ids = [for s in aws_subnet.database : s.id]

  tags = merge(
    local.common_tags,
    {
      Name = "${local.project_name}-${local.env}-db-subnet-group"
    }
  )
}

resource "aws_elasticache_subnet_group" "main" {
  name       = "${local.project_name}-${local.env}-elasticache-subnet-group"
  subnet_ids = [for s in aws_subnet.database : s.id]
}

data "aws_secretsmanager_secret_version" "db_credentials" {
  secret_id = aws_secretsmanager_secret.db_credentials.id
}

locals {
  db_creds = jsondecode(data.aws_secretsmanager_secret_version.db_credentials.secret_string)
}

resource "random_string" "redis_password" {
  length  = 16
  special = false
}

resource "aws_security_group" "elasticache" {
  name_prefix = "${local.project_name}-${local.env}-elasticache-"
  description = "Allow Redis access from Lambda"
  vpc_id      = aws_vpc.main.id

  ingress {
    from_port       = 6379
    to_port         = 6379
    protocol        = "tcp"
    security_groups = [aws_security_group.lambda.id]
  }

  tags = merge(
    local.common_tags,
    {
      Name = "${local.project_name}-${local.env}-elasticache-sg"
    }
  )
}

resource "aws_elasticache_replication_group" "main" {
  replication_group_id       = "${local.project_name}-${local.env}-redis"
  description                = "Redis cluster for ${local.project_name}"
  engine                     = "redis"
  engine_version             = "7.1"
  node_type                  = "cache.t3.micro"
  num_cache_clusters         = 2
  parameter_group_name       = "default.redis7"
  port                       = 6379
  subnet_group_name          = aws_elasticache_subnet_group.main.name
  security_group_ids         = [aws_security_group.elasticache.id]
  automatic_failover_enabled = true
  multi_az_enabled           = true

  auth_token                 = random_string.redis_password.result
  transit_encryption_enabled = true
  at_rest_encryption_enabled = true
  kms_key_id                 = aws_kms_key.main.arn

  apply_immediately = true

  tags = merge(
    local.common_tags,
    {
      Name = "${local.project_name}-${local.env}-redis"
    }
  )
}

resource "aws_db_instance" "main" {
  identifier             = "${local.project_name}-${local.env}-postgres"
  engine                 = "postgres"
  engine_version         = "16.3"
  instance_class         = "db.t3.micro"
  db_subnet_group_name   = aws_db_subnet_group.main.name
  vpc_security_group_ids = [aws_security_group.rds.id]
  multi_az               = false

  username = local.db_creds.username
  password = local.db_creds.password

  db_name = "truetally"
  port    = 5432

  storage_type          = "gp2"
  allocated_storage     = 20
  max_allocated_storage = 20

  backup_retention_period = 1
  backup_window           = "03:00-04:00"
  maintenance_window      = "sun:04:00-sun:05:00"

  performance_insights_enabled = false
  monitoring_interval          = 0

  deletion_protection       = false
  skip_final_snapshot       = local.env == "dev" ? true : false
  final_snapshot_identifier = local.env == "prod" ? "${local.project_name}-${local.env}-final-snapshot" : null

  storage_encrypted = true
  kms_key_id        = aws_kms_key.main.arn

  depends_on = [aws_db_subnet_group.main]

  tags = merge(
    local.common_tags,
    {
      Name = "${local.project_name}-${local.env}-postgres"
    }
  )
}

