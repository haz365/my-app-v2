# ═══════════════════════════════════════════════════════════════
# ECR MODULE — OUTPUTS
# ═══════════════════════════════════════════════════════════════

output "repository_url" {
  description = "Full ECR URL — used to tag and push Docker images"
  value       = aws_ecr_repository.app.repository_url
}

output "repository_name" {
  description = "Just the repository name — used by ECS task definition"
  value       = aws_ecr_repository.app.name
}

output "repository_arn" {
  description = "ECR repository ARN — used by IAM policies"
  value       = aws_ecr_repository.app.arn
}