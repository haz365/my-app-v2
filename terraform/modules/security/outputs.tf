# ═══════════════════════════════════════════════════════════════
# SECURITY MODULE — OUTPUTS
# Both SG IDs are needed by other modules:
# - ALB module needs alb_sg_id to attach to the load balancer
# - ECS module needs ecs_sg_id to attach to Fargate tasks
# ═══════════════════════════════════════════════════════════════

output "alb_sg_id" {
  description = "ALB security group ID"
  value       = aws_security_group.alb.id
}

output "ecs_sg_id" {
  description = "ECS security group ID"
  value       = aws_security_group.ecs.id
}