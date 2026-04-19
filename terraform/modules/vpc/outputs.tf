# ═══════════════════════════════════════════════════════════════
# VPC MODULE — OUTPUTS
# These values are exposed to other modules that need them
# e.g. the ALB module needs public subnet IDs
#      the ECS module needs the private subnet ID
#      the security module needs the VPC ID
# ═══════════════════════════════════════════════════════════════

output "vpc_id" {
  description = "The VPC ID — needed by security groups and other resources"
  value       = aws_vpc.main.id
}

output "public_subnet_ids" {
  description = "List of public subnet IDs — passed to the ALB"
  value       = [aws_subnet.public_a.id, aws_subnet.public_b.id]
}

output "private_subnet_id" {
  description = "Private subnet ID — where ECS Fargate tasks run"
  value       = aws_subnet.private.id
}