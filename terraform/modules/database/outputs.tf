# ═══════════════════════════════════════════════════════════════
# DATABASE MODULE — OUTPUTS
# The ARN is needed by IAM to scope permissions to this table only
# The name is needed by ECS to pass as an environment variable
# ═══════════════════════════════════════════════════════════════

output "table_arn" {
  description = "DynamoDB table ARN — used by IAM to grant permissions"
  value       = aws_dynamodb_table.visit_counter.arn
}

output "table_name" {
  description = "DynamoDB table name — passed to ECS as env var DYNAMO_TABLE"
  value       = aws_dynamodb_table.visit_counter.name
}