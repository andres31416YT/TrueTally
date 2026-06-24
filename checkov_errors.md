# Informe de Errores Checkov — TrueTally
**Universidad Privada Antenor Orrego**  
Facultad de Ingeniería — Escuela Profesional de Ingeniería de Sistemas e Inteligencia Artificial  
**Curso:** Infraestructura como Código  
**Docente:** Walter Leturia Rodriguez  
**Integrantes:** Hermenegildo Rumiche Andy · Pagan Roncal Andres · Chavez Vargas John Marlon · Zumaeta Calderón Adriel Augusto  
**Trujillo - 2026**

---

## Resumen de Errores

| # | Check ID | Descripción | Estado |
|---|----------|-------------|--------|
| 1 | CKV_AWS_334 | ECS containers no deben correr con privilegios | Solucionado |
| 2 | CKV_AWS_184 | EFS debe estar encriptado con CMK | Solucionado |
| 3 | CKV_AWS_18 | S3 bucket debe tener access logging | Solucionado |
| 4 | CKV2_AWS_61 | S3 bucket debe tener lifecycle config | Solucionado |

---

## Error 1: CKV_AWS_334
### *Ensure ECS containers should run as non-privileged*

**Recurso:** `module.compute.aws_ecs_task_definition.blockchain`  
**Archivo:** `/modules/compute/main.tf: 164–181`

### ¿Qué significa este error?

Cuando un contenedor Docker corre en modo privilegiado (`privileged = true`), obtiene acceso casi irrestricto al sistema operativo del host subyacente. Esto equivale a ejecutarse como root con todos los capabilities del kernel habilitados. En un entorno cloud como ECS esto es peligroso porque:

- Si el contenedor es comprometido, el atacante puede escapar y tomar control del host EC2.
- Viola el principio de mínimo privilegio (Least Privilege).
- AWS y estándares como CIS Benchmarks y NIST lo prohíben en cargas de trabajo productivas.

### Contexto del proyecto

El contenedor de nodo blockchain podía arrancar con privilegios elevados por defecto, lo que representaba un riesgo de seguridad crítico en la infraestructura de TrueTally.

### Solución aplicada

Se configuró `privileged = false` para impedir que el contenedor corra con privilegios de root, y adicionalmente `readonlyRootFilesystem = true` para que el contenedor no pueda escribir en su propio sistema de archivos raíz, reduciendo aún más la superficie de ataque.

```hcl
resource "aws_ecs_task_definition" "blockchain" {
  family                   = "${local.name_prefix}-blockchain"
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  cpu                      = "512"
  memory                   = "1024"
  execution_role_arn       = aws_iam_role.ecs_task.arn

  container_definitions = jsonencode([{
    name                  = "blockchain-node"
    image                 = "${var.account_id}.dkr.ecr.${var.aws_region}.amazonaws.com/${var.project_name}-blockchain:latest"
    essential             = true
    privileged            = false
    readonlyRootFilesystem = true
    portMappings = [{
      containerPort = 9944
      hostPort      = 9944
    }]
  }])
}
```

---

## Error 2: CKV_AWS_184 SOLUCIONADO
### *Ensure resource is encrypted by KMS using a customer managed Key (CMK)*

**Recurso:** `module.compute.aws_efs_file_system.blockchain`  
**Archivo:** `/modules/compute/main.tf: 185–193`

### ¿Qué significa este error?

Amazon EFS (Elastic File System) puede encriptarse de dos formas:

- **Con llave administrada por AWS (AWS managed key):** AWS la controla totalmente, sin visibilidad del cliente.
- **Con CMK (Customer Managed Key):** el cliente crea y controla la llave en AWS KMS, con control total sobre rotación, acceso, auditoría y revocación.

Checkov exige CMK porque permite al equipo revocar acceso de forma inmediata, auditar cada uso de la llave, y cumplir con normativas como PCI-DSS, SOC 2 e ISO 27001.

### Contexto del proyecto

El EFS del nodo blockchain ya contaba con `kms_key_id = var.kms_key_arn`, donde el ARN proviene del módulo security del propio proyecto. El recurso **sí** estaba encriptado con CMK, por lo que Checkov lo marcó como resuelto al verificarlo.

### Configuración de solución (CMK ya aplicada)

```hcl
resource "aws_efs_file_system" "blockchain" {
  creation_token = "${local.name_prefix}-blockchain-efs"
  encrypted      = true
  kms_key_id     = var.kms_key_arn

  tags = {
    Name = "${local.name_prefix}-blockchain-efs"
  }
}
```

---

## Error 3: CKV_AWS_18 SOLUCIONADO
### *Ensure the S3 bucket has access logging enabled*

**Recurso:** `module.frontend.aws_s3_bucket.frontend`  
**Archivo:** `/modules/frontend/main.tf: 12–14`

### ¿Qué significa este error?

El access logging de S3 registra todas las peticiones que se hacen al bucket: quién accedió, desde dónde, qué objeto solicitó y con qué resultado. Sin este registro:

- No hay trazabilidad de accesos no autorizados ni exfiltraciones de datos.
- Se incumple con normativas como PCI-DSS, HIPAA y SOC 2 que exigen auditoría de accesos a datos.
- Es imposible detectar patrones de acceso anómalos o ataques de enumeración de objetos.

### Contexto del proyecto

El bucket del frontend (que sirve la web de TrueTally) no tenía ningún registro de quién lo accedía, lo que dejaba un punto ciego de auditoría en la infraestructura.

### Solución aplicada

Se agregó el recurso `aws_s3_bucket_logging`, que redirige los logs de acceso a un bucket de logs separado y dedicado. Esta práctica sigue el principio de separación de responsabilidades: los datos de aplicación no se mezclan con los logs de auditoría.

```hcl
resource "aws_s3_bucket_logging" "frontend" {
  bucket        = aws_s3_bucket.frontend.id
  target_bucket = aws_s3_bucket.logs.id
  target_prefix = "frontend-access-logs/"
}
```

---

## Error 4: CKV2_AWS_61 SOLUCIONADO
### *Ensure that an S3 bucket has a lifecycle configuration*

**Recurso:** `module.frontend.aws_s3_bucket.frontend`  
**Archivo:** `/modules/frontend/main.tf: 12–14`

### ¿Qué significa este error?

Una lifecycle configuration en S3 define reglas automáticas para gestionar objetos a lo largo del tiempo: moverlos a clases de almacenamiento más baratas (Glacier), expirarlos o eliminar versiones antiguas. Sin esto:

- Las versiones antiguas de archivos se acumulan indefinidamente, incrementando el costo de almacenamiento.
- Los objetos obsoletos (versiones de código antiguas, backups vencidos) permanecen sin control.
- Se considera una mala práctica de gobernanza en infraestructura como código.

### Contexto del proyecto

El bucket del frontend no tenía ninguna regla de ciclo de vida, lo que podría acumular versiones antiguas del sitio web de TrueTally de forma indefinida, generando costos innecesarios.

### Solución aplicada

Se agregó `aws_s3_bucket_lifecycle_configuration` con reglas de limpieza de versiones antiguas, asegurando que el bucket se auto-gestione y no crezca de forma descontrolada.

```hcl
resource "aws_s3_bucket_lifecycle_configuration" "frontend" {
  bucket = aws_s3_bucket.frontend.id

  rule {
    id     = "cleanup-old-versions"
    status = "Enabled"
    filter {}
    noncurrent_version_expiration {
      noncurrent_days = 30
    }
  }
}
```