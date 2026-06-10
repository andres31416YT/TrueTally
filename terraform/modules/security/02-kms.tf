resource "random_password" "db_password" {
  length  = 16
  special = false
}

resource "random_password" "jwt_secret" {
  length  = 32
  special = false
}

resource "aws_kms_key" "main" {
  description             = "KMS key for TrueTally infrastructure"
  deletion_window_in_days = 7
  enable_key_rotation     = true

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "Enable IAM User Permissions"
        Effect = "Allow"
        Principal = {
          AWS = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:root"
        }
        Action   = "kms:*"
        Resource = "*"
      }
    ]
  })
}

resource "aws_kms_alias" "main" {
  name          = "alias/${local.name_prefix}-key"
  target_key_id = aws_kms_key.main.key_id
}

data "aws_caller_identity" "current" {}