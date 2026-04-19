# ═══════════════════════════════════════════════════════════════
# ALB MODULE — INPUTS
# ═══════════════════════════════════════════════════════════════

variable "project_name" {
  description = "Name prefix for all resources"
  type        = string
}

variable "vpc_id" {
  description = "VPC ID — target group must live inside the VPC"
  type        = string
}

variable "public_subnet_ids" {
  description = "List of public subnet IDs — ALB spans both"
  type        = list(string)
}

variable "alb_sg_id" {
  description = "ALB security group ID"
  type        = string
}

variable "container_port" {
  description = "Port the container listens on — target group forwards here"
  type        = number
}