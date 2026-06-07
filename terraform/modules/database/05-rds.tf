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
    name        = "log_statement"
    value       = "all"
    apply_method = "pending-reboot"
  }
}

resource "aws_rds_cluster" "main" {
  cluster_identifier      = "${local.name_prefix}-aurora"
  engine                  = "aurora-postgresql"
  engine_mode             = "serverless"
  engine_version          = "15.5"
  database_name           = "truetally"
  master_username         = var.db_username
  master_password         = random_password.db_password.result
  db_cluster_parameter_group_name = aws_rds_cluster_parameter_group.main.name
  db_subnet_group_name    = aws_db_subnet_group.main.name
  vpc_security_group_ids  = [aws_security_group.database.id]
  storage_encrypted       = true
  kms_key_id              = aws_kms_key.main.arn
  skip_final_snapshot     = false
  final_snapshot_identifier = "${local.name_prefix}-aurora-final-${formatdate("YYYY-MM-DD-hhmm", timestamp())}"

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
  identifier              = "${local.name_prefix}-aurora-instance-1"
  cluster_identifier      = aws_rds_cluster.main.id
  engine                  = "aurora-postgresql"
  engine_version          = "15.5"
  instance_class          = "db.serverless"
  db_subnet_group_name    = aws_db_subnet_group.main.name
  publicly_accessible     = false
  monitoring_interval     = 60
  monitoring_role_arn     = aws_iam_role.rds_monitoring.arn
  ca_cert_identifier      = "rds-ca-rsa2048-g1"

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
  secret_id   = aws_secretsmanager_secret.db_credentials.id
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