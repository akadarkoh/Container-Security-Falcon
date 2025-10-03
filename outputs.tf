output "website_bucket_name" {
  value       = aws_s3_bucket.website_bucket.bucket
  description = "Name of the S3 bucket hosting the static site."
}

output "alb_dns_name" {
  value       = aws_lb.falcon_alb.dns_name
  description = "Public DNS name for the ECS service Application Load Balancer."
}

output "ecr_repository_url" {
  value       = aws_ecr_repository.falcon_ecr_repository.repository_url
  description = "URL of the ECR repository storing container images."
}
