# Checkov Errors - TrueTally

# Checkov Security Errors - TrueTally Terraform

## Error 1: CKV_AWS_334
**Ensure ECS containers should run as non-privileged**
- Resource: `module.compute.aws_ecs_task_definition.blockchain`
- File: `/modules/compute/main.tf: 164-181`
- **Contexto del proyecto:** El contenedor de nodo blockchain por defecto puede ejecutarse con privilegios elevados, lo cual es un riesgo de seguridad. 
- **Error:** El contenedor no tenía configuración de seguridad.

**Solución aplicada:** Agregué `privileged = false` y `readonlyRootFilesystem = true` en la definición del contenedor.

**Solucion:**
```terraform
container_definitions = jsonencode([{
  name                  = "blockchain-node"
  image                 = "${var.account_id}.dkr.ecr.${var.aws_region}.amazonaws.com/${var.project_name}-blockchain:latest"
  essential             = true
  privileged            = false
  readonlyRootFilesystem = true
  portMappings          = [{
    containerPort = 9944
    hostPort      = 9944
  }]
}])
```

## Error 2: CKV_AWS_184 (SOLUCIONADO)
**Ensure resource is encrypted by KMS using a customer managed Key (CMK)**
- Resource: `module.compute.aws_efs_file_system.blockchain`
- File: `/modules/compute/main.tf: 185-193`
- **Contexto del proyecto:** El EFS tiene `kms_key_id = var.kms_key_arn`. El KMS key ARN proviene del módulo security.



## Error 3: CKV_AWS_18
**Ensure the S3 bucket has access logging enabled**
- Resource: `module.frontend.aws_s3_bucket.frontend`
- File: `/modules/frontend/main.tf: 12-14`
- **Contexto del proyecto:** El bucket de frontend estático no tiene logging de acceso habilitado.
- **Error:** No hay configuración de access logging.

## Error 4: CKV2_AWS_61
**Ensure that an S3 bucket has a lifecycle configuration**
- Resource: `module.frontend.aws_s3_bucket.frontend`
- File: `/modules/frontend/main.tf: 12-14`
- **Contexto del proyecto:** El bucket de frontend no tiene política de lifecycle para limpieza de objetos.
- **Error:** No hay lifecycle configuration.

## Error 5: CKV2_AWS_11
**Ensure VPC flow logging is enabled in all VPCs**
- Resource: `module.networking.aws_vpc.main`
- File: `/modules/networking/main.tf: 10-15`
- **Contexto del proyecto:** La VPC no tiene flow logs habilitados para monitoreo de tráfico.
- **Error:** No hay flow log configuration.
