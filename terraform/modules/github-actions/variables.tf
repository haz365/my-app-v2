# ═══════════════════════════════════════════════════════════════
# GITHUB ACTIONS MODULE — INPUTS
# ═══════════════════════════════════════════════════════════════

variable "project_name" {
  description = "Name prefix for all resources"
  type        = string
}

variable "github_org" {
  description = "Your GitHub username or organisation"
  type        = string
}

variable "github_repo" {
  description = "Your GitHub repository name"
  type        = string
}

variable "ecr_repository_arn" {
  description = "ECR repository ARN — GitHub Actions needs push access"
  type        = string
}

variable "ecs_cluster_name" {
  description = "ECS cluster name — GitHub Actions triggers deployments here"
  type        = string
}

variable "ecs_service_name" {
  description = "ECS service name"
  type        = string
}