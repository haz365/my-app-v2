# ═══════════════════════════════════════════════════════════════
# IAM MODULE — INPUTS
# ═══════════════════════════════════════════════════════════════

variable "project_name" {
  description = "Name prefix for all resources"
  type        = string
}

variable "dynamodb_table_arn" {
  description = "ARN of the DynamoDB visit counter table"
  type        = string
}