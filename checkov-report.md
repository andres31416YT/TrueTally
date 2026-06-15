# Checkov Security Scan Report - TrueTally Terraform

## Error Detectado: CKV2_AWS_46

**Política:** Ensure AWS CloudFront Distribution with S3 have Origin Access set to enabled

**Severidad:** MEDIUM

**Descripción:** Cuando CloudFront está conectado a un origen S3, debe usarse Origin Access Identity (OAI) para evitar que el bucket sea accesible públicamente. Sin OAI, cualquier usuario puede acceder directamente al bucket S3 si las políticas lo permiten.

## Antes (Código con fallo)

```terraform
resource "aws_cloudfront_distribution" "frontend" {
  # ... omitted for brevity ...
  
  origin {
    domain_name = aws_s3_bucket.frontend.bucket_regional_domain_name
    origin_id   = "s3-origin"
    # FALTA s3_origin_config con OAI
  }
}
```

**Resultado Checkov:** FAILED

## Solución Implementada

Se agregaron 3 recursos:

1. **Origin Access Identity**
```terraform
resource "aws_cloudfront_origin_access_identity" "frontend" {
  comment = "OAI for ${local.name_prefix} frontend"
}
```

2. **Bucket Policy** (permite acceso solo al OAI)
```terraform
resource "aws_s3_bucket_policy" "frontend" {
  bucket = aws_s3_bucket.frontend.id
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Sid       = "AllowCloudFrontAccess"
      Effect    = "Allow"
      Principal = { AWS = aws_cloudfront_origin_access_identity.frontend.iam_arn }
      Action    = "s3:GetObject"
      Resource  = "${aws_s3_bucket.frontend.arn}/*"
    }]
  })
}
```

3. **Actualización del CloudFront Distribution**
```terraform
origin {
  domain_name = aws_s3_bucket.frontend.bucket_regional_domain_name
  origin_id   = "s3-origin"
  
  s3_origin_config {
    origin_access_identity = aws_cloudfront_origin_access_identity.frontend.cdn_aws_source_arn
  }
}
```

## Después (Código corregido)

**Resultado Checkov:** PASSED

## Beneficios de la solución

- El bucket S3 solo es accesible a través de CloudFront (no directamente)
- Política de seguridad en profundidad (defensa en capas)
- Cumple con estándares de compliance AWS
- Protege contra acceso no autorizado a contenido estático