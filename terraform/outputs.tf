# ═══════════════════════════════════════════════════════════════
# ROOT OUTPUTS
# Printed after terraform apply finishes
# ═══════════════════════════════════════════════════════════════

output "ecr_repository_url" {
  description = "ECR URL — use when tagging and pushing Docker images"
  value       = module.ecr.repository_url
}

output "alb_dns_name" {
  description = "ALB DNS — use to test before domain is wired up"
  value       = module.alb.alb_dns_name
}

output "route53_nameservers" {
  description = "Paste these 4 values into GoDaddy custom nameservers"
  value       = module.route53.nameservers
}

output "cloudwatch_log_group" {
  description = "View container logs here in CloudWatch"
  value       = module.ecs.log_group_name
}

output "site_url" {
  description = "Your live site URL"
  value       = "https://${var.domain_name}"
}

output "ecs_cluster_name" {
  description = "ECS cluster name"
  value       = module.ecs.cluster_name
}

output "ecs_service_name" {
  description = "ECS service name"
  value       = module.ecs.service_name
}

output "github_actions_role_arn" {
  description = "Paste this into your GitHub Actions workflow"
  value       = module.github_actions.role_arn
}