# ═══════════════════════════════════════════════════════════════
# SECURITY MODULE
# Creates two security groups (virtual firewalls):
#
# 1. ALB SECURITY GROUP
#    - Allows HTTP (80) and HTTPS (443) from the internet
#    - Allows all outbound traffic
#
# 2. ECS SECURITY GROUP
#    - Only allows traffic FROM the ALB security group
#    - The internet CANNOT reach ECS directly
#    - This is the key security pattern for private subnets
# ═══════════════════════════════════════════════════════════════


# ─── ALB Security Group ───────────────────────────────────────
# The ALB is internet-facing so it needs to accept public traffic
resource "aws_security_group" "alb" {
  name        = "${var.project_name}-alb-sg"
  description = "Controls traffic to and from the ALB"
  vpc_id      = var.vpc_id

  # ── Inbound rules ──────────────────────────────────────────

  # Allow HTTP from anywhere on the internet
  ingress {
    description = "HTTP from internet"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]   # 0.0.0.0/0 = entire internet
  }

  # Allow HTTPS from anywhere on the internet
  ingress {
    description = "HTTPS from internet"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # ── Outbound rules ─────────────────────────────────────────

  # Allow all outbound so ALB can forward requests to ECS tasks
  egress {
    description = "Allow all outbound"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"            # -1 = all protocols
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "${var.project_name}-alb-sg"
  }
}


# ─── ECS Security Group ───────────────────────────────────────
# ECS tasks live in the private subnet
# They should ONLY accept traffic from the ALB — nothing else
resource "aws_security_group" "ecs" {
  name        = "${var.project_name}-ecs-sg"
  description = "Controls traffic to and from ECS Fargate tasks"
  vpc_id      = var.vpc_id

  # ── Inbound rules ──────────────────────────────────────────

  # ONLY allow traffic from the ALB security group on our app port
  # Notice: no cidr_blocks here — we reference the ALB's SG directly
  # Translation: "only accept traffic from things in the ALB's SG"
  # Even if someone knew the private IP of our container, they
  # couldn't reach it because this rule blocks everything else
  ingress {
    description     = "Traffic from ALB to container"
    from_port       = var.container_port   # 3000
    to_port         = var.container_port
    protocol        = "tcp"
    security_groups = [aws_security_group.alb.id]
  }

  # ── Outbound rules ─────────────────────────────────────────

  # Allow all outbound so containers can:
  # - Pull images from ECR (via NAT)
  # - Write logs to CloudWatch (via NAT)
  # - Talk to DynamoDB (via NAT or VPC endpoint)
  egress {
    description = "Allow all outbound"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "${var.project_name}-ecs-sg"
  }
}