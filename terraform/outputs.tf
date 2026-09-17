# Values printed after `terraform apply` (and via `terraform output`).

output "ecr_repository_url" {
  description = "Where to docker push the image."
  value       = aws_ecr_repository.api.repository_url
}

output "api_base_url" {
  description = "Public base URL of the API. Try <this>/health and <this>/fighters/search?q=jones."
  value       = aws_apigatewayv2_stage.default.invoke_url
}

output "frontend_bucket" {
  description = "S3 bucket to upload the built frontend (dist/) into."
  value       = aws_s3_bucket.frontend.id
}

output "cloudfront_url" {
  description = "Public HTTPS URL of the deployed frontend."
  value       = "https://${aws_cloudfront_distribution.frontend.domain_name}"
}

output "cloudfront_distribution_id" {
  description = "CloudFront distribution ID (used for cache invalidations)."
  value       = aws_cloudfront_distribution.frontend.id
}
