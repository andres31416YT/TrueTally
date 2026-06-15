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


