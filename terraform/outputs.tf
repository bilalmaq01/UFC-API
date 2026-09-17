# Values printed after `terraform apply` (and via `terraform output`).

output "ecr_repository_url" {
  description = "Where to docker push the image."
  value       = aws_ecr_repository.api.repository_url
}

output "api_base_url" {
  description = "Public base URL of the API. Try <this>/health and <this>/fighters/search?q=jones."
  value       = aws_apigatewayv2_stage.default.invoke_url
}
