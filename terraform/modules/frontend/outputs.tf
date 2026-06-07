output "frontend_bucket_name" { value = aws_s3_bucket.frontend.id }
output "frontend_cloudfront_id" { value = aws_cloudfront_distribution.frontend.id }
output "frontend_domain" { value = local.use_custom_domain ? var.domain_name : aws_cloudfront_distribution.frontend.domain_name }
output "frontend_url" { value = local.use_custom_domain ? "https://${var.domain_name}" : "https://${aws_cloudfront_distribution.frontend.domain_name}" }
