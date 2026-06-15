# Checkov Security Errors - TrueTally Terraform

## Error 3: CKV_AWS_184
**Ensure resource is encrypted by KMS using a customer managed Key (CMK)**
- Resource: `module.compute.aws_efs_file_system.blockchain`
- File: `/modules/compute/main.tf: 185-193`
- **Contexto:** EFS necesita CMK para encriptación.
- **Estado:** VERIFICANDO - El recurso TIENE `kms_key_id = var.kms_key_arn`.
