# ═══════════════════════════════════════════════════════════════
# ECS MODULE — INPUTS
# ═══════════════════════════════════════════════════════════════

variable "project_name" {
  description = "Name prefix for all resources"
  type        = string
}

variable "region" {
  description = "AWS region"
  type        = string
}

variable "container_port" {
  description = "Port the Node.js container listens on"
  type        = number
}

variable "desired_count" {
  description = "How many Fargate tasks to run"
  type        = number
}

variable "ecr_repository_url" {
  description = "Full ECR URL to pull the Docker image from"
  type        = string
}

variable "private_subnet_id" {
  description = "Private subnet ID where Fargate tasks run"
  type        = string
}

variable "ecs_sg_id" {
  description = "ECS security group ID"
  type        = string
}

variable "target_group_arn" {
  description = "ALB target group ARN — tasks register here"
  type        = string
}

variable "task_execution_role_arn" {
  description = "Task execution role ARN — used by ECS to start containers"
  type        = string
}

variable "task_role_arn" {
  description = "Task role ARN — used by app code at runtime"
  type        = string
}

variable "dynamodb_table_name" {
  description = "DynamoDB table name passed to container as env var"
  type        = string
}

variable "alb_listener_arn" {
  description = "ALB HTTP listener ARN — ECS service depends on it"
  type        = string
}

variable "certificate_arn" {
  description = "ACM certificate ARN — for HTTPS listener"
  type        = string
}

variable "alb_arn" {
  description = "ALB ARN — needed to attach HTTPS listener"
  type        = string
}