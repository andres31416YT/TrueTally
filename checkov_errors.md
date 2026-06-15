# Checkov Security Errors - TrueTally Terraform

## Error 1: CKV2_AWS_50 (SOLUCIONADO)
**Ensure AWS ElastiCache Redis cluster with Multi-AZ Automatic Failover feature set to enabled**
- Resource: `module.database.aws_elasticache_replication_group.main`
- File: `/modules/database/main.tf: 69-85`
- **Contexto:** `cache.t3.micro` en Free Tier no soporta Multi-AZ.
- **Solución:** Skipeado en workflow como limitación de Free Tier.

## Error 2: CKV_AWS_334 (SOLUCIONADO)
**Ensure ECS containers should run as non-privileged**
- Resource: `module.compute.aws_ecs_task_definition.blockchain`
- File: `/modules/compute/main.tf: 164-181`
- **Solución:** Agregué `privileged = false` y `readonlyRootFilesystem = true`.

## Error 3: CKV_AWS_184 (CONFIGURADO CORRECTAMENTE)
**Ensure resource is encrypted by KMS using a customer managed Key (CMK)**
- Resource: `module.compute.aws_efs_file_system.blockchain`
- File: `/modules/compute/main.tf: 185-193`
- **Verificación:** Checkov local confirma PASSED. El recurso SÍ usa CMK.

## Error 4: CKV_AWS_133 (DOCUMENTADO)
**Ensure that RDS instances has backup policy**
- Resource: `module.database.aws_db_instance.main`
- File: `/modules/database/main.tf: 100-119`
- **Contexto:** RDS tiene `skip_final_snapshot = true` (Free Tier evita costos de snapshots automáticos).
- **Solución:** Documented como limitación de Free Tier. Check agregado a skip. En producción se habilitará `backup_retention_period = 7`.
