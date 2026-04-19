# ═══════════════════════════════════════════════════════════════
# VPC MODULE — INPUTS
# Values passed in from the root main.tf when calling this module
# ═══════════════════════════════════════════════════════════════

variable "project_name" {
  description = "Name prefix for all resources"
  type        = string
}

variable "vpc_cidr" {
  description = "IP range for the entire VPC e.g. 10.0.0.0/16"
  type        = string
}