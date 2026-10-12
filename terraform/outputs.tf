output "frontend_ecr_repository_url" {
  description = "ECR repository URL for the TaskForge frontend"
  value       = aws_ecr_repository.frontend.repository_url
}

output "backend_ecr_repository_url" {
  description = "ECR repository URL for the TaskForge backend"
  value       = aws_ecr_repository.backend.repository_url
}