# ═══════════════════════════════════════════════════════════════
# IAM MODULE — OUTPUTS
# Both role ARNs are needed by the ECS task definition
# ═══════════════════════════════════════════════════════════════

output "task_execution_role_arn" {
  description = "ARN of the task execution role — passed to ECS task definition"
  value       = aws_iam_role.task_execution.arn
}

output "task_role_arn" {
  description = "ARN of the task role — used by app code at runtime"
  value       = aws_iam_role.task.arn
}