# ═══════════════════════════════════════════════════════════════
# ACM MODULE — OUTPUTS
# ═══════════════════════════════════════════════════════════════

output "certificate_arn" {
  description = "Validated certificate ARN — attached to ALB HTTPS listener"
  value       = aws_acm_certificate_validation.main.certificate_arn
}