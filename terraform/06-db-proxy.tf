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
    username    = jsondecode(aws_secretsmanager_secret_version.db_credentials.secret_string)["username"]
  }

  tags = {
    Name = "${local.name_prefix}-aurora-proxy"
  }
}

resource "aws_db_proxy_target" "main" {
  db_instance_identifier = aws_rds_cluster_instance.main.id
  db_cluster_identifier  = aws_rds_cluster.main.id
  proxy_name             = aws_db_proxy.main.name
  target_role            = "READ_WRITE"
}