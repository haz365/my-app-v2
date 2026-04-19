# ═══════════════════════════════════════════════════════════════
# ALB MODULE — OUTPUTS
# ═══════════════════════════════════════════════════════════════

output "alb_dns_name" {
  description = "ALB DNS name — use to test before domain is wired up"
  value       = aws_lb.main.dns_name
}

output "alb_zone_id" {
  description = "ALB hosted zone ID — needed by Route 53 alias record"
  value       = aws_lb.main.zone_id
}

output "alb_arn" {
  description = "ALB ARN — needed to attach HTTPS listener later"
  value       = aws_lb.main.arn
}

output "target_group_arn" {
  description = "Target group ARN — ECS service registers tasks here"
  value       = aws_lb_target_group.app.arn
}

output "http_listener_arn" {
  description = "HTTP listener ARN"
  value       = aws_lb_listener.http.arn
}