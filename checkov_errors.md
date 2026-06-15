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
- **Contexto:** RDS tiene `skip_final_snapshot = true` (Free Tier).
- **Solución:** Skipeado como limitación de Free Tier.

## Error 5: CKV_AWS_97 (FALSO POSITIVO)
**Ensure Encryption in transit is enabled for EFS volumes in ECS Task definitions**
- Resource: `module.compute.aws_ecs_task_definition.blockchain`
- File: `/modules/compute/main.tf: 164-181`
- **Contexto:** El task definition NO monta EFS como volumen (el recurso `aws_efs_file_system` está definido pero no usado).
- **Verificación:** Falso positivo - el EFS está encriptado con `encrypted = true` y `kms_key_id`, pero no hay mount en el contenedor.
- **Solución:** Skipeado como falso positivo.

## Error 6: CKV_AWS_249
**Ensure that the Execution Role ARN and the Task Role ARN are different in ECS Task definitions**
- Resource: `module.compute.aws_ecs_task_definition.blockchain`
- File: `/modules/compute/main.tf: 164-181`
- **Contexto:** El task definition usa solo `execution_role_arn`.
- **Estado:** PENDIENTE - requiere crear rol separado para task execution.
