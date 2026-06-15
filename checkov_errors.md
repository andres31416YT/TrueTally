# Checkov Security Errors - TrueTally Terraform

## Error 1: CKV2_AWS_50
**Ensure AWS ElastiCache Redis cluster with Multi-AZ Automatic Failover feature set to enabled**
- Resource: `module.database.aws_elasticache_replication_group.main`
- File: `/modules/database/main.tf: 69-85`
- Causa: `automatic_failover_enabled = false` y `multi_az_enabled = false`

## Error 2: CKV_AWS_334
**Ensure ECS containers should run as non-privileged**
- Resource: `module.compute.aws_ecs_task_definition.blockchain`
- File: `/modules/compute/main.tf`
- Causa: Container corre como privileged por defecto

## Error 3: CKV_AWS_184
**Ensure resource is encrypted by KMS using a customer managed Key (CMK)**
- Resource: `module.compute.aws_efs_file_system.blockchain`
- File: `/modules/compute/main.tf`
- Causa: EFS usa KMS pero no con CMK administrado por el cliente

## Error 4: CKV_AWS_133
**Ensure that RDS instances has backup policy**
- Resource: `module.database.aws_db_instance.main`
- File: `/modules/database/main.tf: 100-119`
- Causa: Falta configuración de backup (backup_retention_period)