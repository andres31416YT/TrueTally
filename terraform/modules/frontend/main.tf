locals {
  name_prefix = "${var.project_name}-${var.env}"
  bucket_suffix = var.bucket_suffix != "" ? "-${var.bucket_suffix}" : ""
  frontend_bucket = "${local.name_prefix}-frontend${local.bucket_suffix}"
  logs_bucket = "${local.name_prefix}-logs${local.bucket_suffix}"
}

data "aws_caller_identity" "current" {}

terraform {
  required_providers {
    aws = {
      source                = "hashicorp/aws"
      version               = "~> 5.0"
      configuration_aliases = [aws.us_east_1]
    }
  }
}

resource "aws_s3_bucket" "logs" {
  count  = var.enabled ? 1 : 0
  bucket = local.logs_bucket
}

resource "aws_s3_bucket_versioning" "logs" {
  count  = var.enabled ? 1 : 0
  bucket = aws_s3_bucket.logs[0].id

  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "logs" {
  count  = var.enabled ? 1 : 0
  bucket = aws_s3_bucket.logs[0].id

  rule {
    apply_server_side_encryption_by_default {
      kms_master_key_id = var.kms_key_arn
      sse_algorithm     = "aws:kms"
    }
  }
}

resource "aws_s3_bucket" "frontend" {
  count  = var.enabled ? 1 : 0
  bucket = local.frontend_bucket
}

resource "aws_s3_bucket_versioning" "frontend" {
  count  = var.enabled ? 1 : 0
  bucket = aws_s3_bucket.frontend[0].id

  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "frontend" {
  count  = var.enabled ? 1 : 0
  bucket = aws_s3_bucket.frontend[0].id

  rule {
    apply_server_side_encryption_by_default {
      kms_master_key_id = var.kms_key_arn
      sse_algorithm     = "aws:kms"
    }
  }
}

resource "aws_s3_bucket_logging" "frontend" {
  count         = var.enabled ? 1 : 0
  bucket        = aws_s3_bucket.frontend[0].id
  target_bucket = aws_s3_bucket.logs[0].id
  target_prefix = "frontend-access-logs/"
}

resource "aws_s3_bucket_lifecycle_configuration" "frontend" {
  count  = var.enabled ? 1 : 0
  bucket = aws_s3_bucket.frontend[0].id

  rule {
    id     = "cleanup-old-versions"
    status = "Enabled"
    filter {}
    noncurrent_version_expiration {
      noncurrent_days = 30
    }
  }
}

resource "aws_s3_bucket_public_access_block" "frontend" {
  count  = var.enabled ? 1 : 0
  bucket = aws_s3_bucket.frontend[0].id

  block_public_acls       = false
  block_public_policy     = false
  ignore_public_acls      = false
  restrict_public_buckets = false
}

resource "aws_s3_bucket_policy" "frontend" {
  count  = var.enabled ? 1 : 0
  bucket = aws_s3_bucket.frontend[0].id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect    = "Allow"
        Principal = {
          Service = "cloudfront.amazonaws.com"
        }
        Action   = "s3:GetObject"
        Resource = "${aws_s3_bucket.frontend[0].arn}/*"
        Condition = {
          StringEquals = {
            "AWS:SourceArn" = "arn:aws:cloudfront::${data.aws_caller_identity.current.account_id}:distribution/${aws_cloudfront_distribution.frontend[0].id}"
          }
        }
      }
    ]
  })
}

resource "aws_s3_bucket_website_configuration" "frontend" {
  count  = var.enabled ? 1 : 0
  bucket = aws_s3_bucket.frontend[0].id

  index_document {
    suffix = "index.html"
  }

  error_document {
    key = "index.html"
  }
}

resource "aws_acm_certificate" "frontend" {
  count = var.enabled && var.create_acm_certificate && var.ssl_certificate_arn == "" ? 1 : 0

  provider          = aws.us_east_1
  domain_name       = var.domain_name
  validation_method = "DNS"

  lifecycle {
    create_before_destroy = true
  }

  tags = {
    Name = "${local.name_prefix}-acm-cert"
  }
}

resource "aws_acm_certificate_validation" "frontend" {
  count = var.enabled && var.create_acm_certificate && var.ssl_certificate_arn == "" ? 1 : 0

  provider        = aws.us_east_1
  certificate_arn = aws_acm_certificate.frontend[0].arn
}

resource "aws_cloudfront_origin_access_control" "frontend" {
  name                              = "${local.name_prefix}-oac"
  description                       = "OAC for ${local.name_prefix} frontend"
  origin_access_control_origin_type = "s3"
  signing_behavior                  = "always"
  signing_protocol                  = "sigv4"
}

resource "aws_cloudfront_distribution" "frontend" {
  count               = var.enabled ? 1 : 0
  enabled             = true
  is_ipv6_enabled     = true
  comment             = "Frontend for ${local.name_prefix}"
  default_root_object = "index.html"

  aliases = var.create_acm_certificate && var.ssl_certificate_arn != "" ? [var.domain_name] : []

  default_cache_behavior {
    allowed_methods  = ["GET", "HEAD", "OPTIONS"]
    cached_methods   = ["GET", "HEAD"]
    target_origin_id = "s3-origin"

    forwarded_values {
      query_string = false
      cookies {
        forward = "none"
      }
    }

    viewer_protocol_policy = "redirect-to-https"
    min_ttl                = 0
    default_ttl            = 3600
    max_ttl                = 86400
    compress               = true
  }

  restrictions {
    geo_restriction {
      restriction_type = "none"
    }
  }

  dynamic "viewer_certificate" {
    for_each = var.create_acm_certificate && var.ssl_certificate_arn != "" ? [1] : []
    content {
      acm_certificate_arn      = var.ssl_certificate_arn
      ssl_support_method       = "sni-only"
      minimum_protocol_version = "TLSv1.2_2021"
    }
  }

  dynamic "viewer_certificate" {
    for_each = !(var.create_acm_certificate && var.ssl_certificate_arn != "") ? [1] : []
    content {
      cloudfront_default_certificate = true
    }
  }

  origin {
    domain_name              = "${local.frontend_bucket}.s3-website-${var.aws_region}.amazonaws.com"
    origin_id                = "s3-origin"
    origin_access_control_id = aws_cloudfront_origin_access_control.frontend.id

    custom_origin_config {
      http_port                = 80
      https_port               = 443
      origin_protocol_policy   = "http-only"
      origin_ssl_protocols     = ["TLSv1.2"]
      origin_read_timeout      = 30
      origin_keepalive_timeout = 5
    }

    custom_header {
      name  = "Host"
      value = "${local.frontend_bucket}.s3-website-${var.aws_region}.amazonaws.com"
    }
  }
}

output "s3_bucket_name" {
  value = var.enabled ? aws_s3_bucket.frontend[0].id : ""
}

output "cloudfront_domain_name" {
  value = var.enabled ? aws_cloudfront_distribution.frontend[0].domain_name : ""
}

output "cloudfront_distribution_id" {
  value = var.enabled ? aws_cloudfront_distribution.frontend[0].id : ""
}

output "acm_certificate_arn" {
  value = var.enabled && var.create_acm_certificate && length(aws_acm_certificate.frontend) > 0 ? aws_acm_certificate.frontend[0].arn : ""
}