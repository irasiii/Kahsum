output "alb_dns_name" {
  description = "ALB DNS name"
  value       = aws_lb.main.dns_name
}

output "ecr_repository_url" {
  description = "ECR repository URL"
  value       = aws_ecr_repository.backend.repository_url
}

output "rds_endpoint" {
  description = "RDS endpoint"
  value       = aws_db_instance.postgres.endpoint
  sensitive   = true
}

output "flutter_web_cloudfront_url" {
  description = "Flutter web CloudFront URL"
  value       = aws_cloudfront_distribution.flutter_web.domain_name
}

output "nextjs_site_cloudfront_url" {
  description = "Next.js site CloudFront URL"
  value       = aws_cloudfront_distribution.nextjs_site.domain_name
}

output "flutter_web_bucket" {
  description = "Flutter web S3 bucket"
  value       = aws_s3_bucket.flutter_web.id
}

output "nextjs_site_bucket" {
  description = "Next.js site S3 bucket"
  value       = aws_s3_bucket.nextjs_site.id
}
