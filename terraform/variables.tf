# ═══════════════════════════════════════════════════════════════
# ROOT VARIABLES
# These are the inputs to the entire Terraform project
# Referenced as var.xyz throughout all files
# ═══════════════════════════════════════════════════════════════

variable "region" {
  description = "AWS region to deploy everything into"
  type        = string
  default     = "eu-west-2"   # London
}

variable "project_name" {
  description = "Name prefix applied to every resource we create"
  type        = string
  default     = "my-app-v2"
}

variable "vpc_cidr" {
  description = "IP range for the entire VPC"
  type        = string
  default     = "10.0.0.0/16"
}

variable "container_port" {
  description = "Port the Node.js app listens on inside the container"
  type        = number
  default     = 3000
}

variable "domain_name" {
  description = "Your domain name e.g. mydomain.com"
  type        = string
  # No default — Terraform will prompt you for this
}

variable "desired_count" {
  description = "How many Fargate tasks to run"
  type        = number
  default     = 1   # 1 for cost savings while learning
}

variable "github_org" {
  description = "Your GitHub username or organisation name"
  type        = string
}

variable "github_repo" {
  description = "Your GitHub repository name"
  type        = string
}