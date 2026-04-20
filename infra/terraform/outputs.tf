output "alb_dns_name" {
  description = "Point api.physioconnect.in CNAME to this value"
  value       = aws_lb.api.dns_name
}

output "alb_zone_id" {
  description = "ALB hosted zone ID (for Route 53 alias records)"
  value       = aws_lb.api.zone_id
}

output "rds_endpoint" {
  description = "RDS MySQL endpoint — use as DB_HOST in .env.production"
  value       = aws_db_instance.main.endpoint
  sensitive   = true
}

output "redis_primary_endpoint" {
  description = "Redis primary endpoint — use as REDIS_HOST in .env.production"
  value       = aws_elasticache_replication_group.main.primary_endpoint_address
  sensitive   = true
}

output "ecr_repository_url" {
  description = "ECR repository URL — use in docker push and GitHub Actions secrets"
  value       = aws_ecr_repository.api.repository_url
}

output "admin_s3_bucket" {
  description = "S3 bucket name for admin panel — use as ADMIN_S3_BUCKET in GitHub secrets"
  value       = aws_s3_bucket.admin.bucket
}

output "admin_cloudfront_domain" {
  description = "CloudFront domain for admin panel"
  value       = aws_cloudfront_distribution.admin.domain_name
}

output "admin_cloudfront_distribution_id" {
  description = "CloudFront distribution ID — use as ADMIN_CF_DISTRIBUTION in GitHub secrets"
  value       = aws_cloudfront_distribution.admin.id
}

output "vpc_id" {
  value = aws_vpc.main.id
}

output "private_subnet_ids" {
  value = aws_subnet.private[*].id
}

output "public_subnet_ids" {
  value = aws_subnet.public[*].id
}

output "github_actions_summary" {
  description = "Copy these values into GitHub Actions secrets"
  value = {
    ECR_REGISTRY             = split("/", aws_ecr_repository.api.repository_url)[0]
    ECR_REPO                 = aws_ecr_repository.api.name
    ADMIN_S3_BUCKET          = aws_s3_bucket.admin.bucket
    ADMIN_CF_DISTRIBUTION    = aws_cloudfront_distribution.admin.id
  }
}
