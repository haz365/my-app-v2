# ═══════════════════════════════════════════════════════════════
# GITHUB ACTIONS MODULE — OUTPUTS
# ═══════════════════════════════════════════════════════════════

output "role_arn" {
  description = "Role ARN to paste into GitHub Actions workflow"
  value       = aws_iam_role.github_actions.arn
}