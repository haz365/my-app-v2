# ═══════════════════════════════════════════════════════════════
# SECURITY MODULE — INPUTS
# ═══════════════════════════════════════════════════════════════

variable "project_name" {
  description = "Name prefix for all resources"
  type        = string
}

variable "vpc_id" {
  description = "VPC ID — security groups must live inside a VPC"
  type        = string
}

variable "container_port" {
  description = "Port the Node.js container listens on (3000)"
  type        = number
}