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