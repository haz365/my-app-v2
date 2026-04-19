# ═══════════════════════════════════════════════════════════════
# ALB MODULE
# Creates the Application Load Balancer and supporting resources:
#
# 1. ALB — the actual load balancer (lives in public subnets)
# 2. TARGET GROUP — pool of ECS tasks to send traffic to
# 3. HTTP LISTENER — redirects port 80 → 443 (HTTPS)
# 4. HTTPS LISTENER — forwards port 443 to the target group
#
# Note: HTTPS listener needs the ACM certificate ARN
# We add it after the ACM module is created
# ═══════════════════════════════════════════════════════════════

# ─── Application Load Balancer ────────────────────────────────
# The public-facing entry point for all user traffic
# Lives in public subnets — has a public DNS name
# AWS manages the underlying infrastructure automatically
resource "aws_lb" "main" {
  name               = "${var.project_name}-alb"
  internal           = false              # false = internet facing
  load_balancer_type = "application"      # Layer 7 (HTTP/HTTPS aware)

  # Span both public subnets for availability
  # ALB requires at least 2 subnets in different AZs
  subnets         = var.public_subnet_ids

  # Attach the ALB security group (allows 80 + 443 from internet)
  security_groups = [var.alb_sg_id]

  # Set to true for real production to prevent accidental deletion
  enable_deletion_protection = false

  tags = {
    Name = "${var.project_name}-alb"
  }
}


# ─── Target Group ─────────────────────────────────────────────
# The pool of ECS tasks the ALB forwards traffic to
# ECS automatically registers/deregisters tasks as they start/stop
resource "aws_lb_target_group" "app" {
  name = "${var.project_name}-tg"

  # The port our Node.js app listens on inside the container
  port     = var.container_port
  protocol = "HTTP"

  # "ip" type is required for Fargate
  # (EC2 mode uses "instance" type instead)
  target_type = "ip"

  vpc_id = var.vpc_id

  # ── Health Check ───────────────────────────────────────────
  # ALB pings this endpoint on each container regularly
  # If it fails enough times, the container is removed from rotation
  # This is how ALB knows which containers are healthy
  health_check {
    enabled             = true
    path                = "/health"      # Our health endpoint in server.js
    protocol            = "HTTP"
    port                = "traffic-port" # Same port as traffic (3000)
    healthy_threshold   = 2              # 2 passes = healthy
    unhealthy_threshold = 3              # 3 fails = unhealthy
    timeout             = 5              # Wait 5s for response
    interval            = 30             # Check every 30 seconds
    matcher             = "200"          # Must return HTTP 200
  }

  # How long ALB waits for in-flight requests to complete
  # before removing a task during a deployment or scale-in
  deregistration_delay = 30

  tags = {
    Name = "${var.project_name}-tg"
  }
}


# ─── HTTP Listener (port 80) ──────────────────────────────────
# Instead of forwarding HTTP traffic, we redirect to HTTPS
# This ensures all traffic is encrypted
# Users typing http:// get automatically bumped to https://
resource "aws_lb_listener" "http" {
  load_balancer_arn = aws_lb.main.arn
  port              = 80
  protocol          = "HTTP"

  default_action {
    type = "redirect"

    redirect {
      port        = "443"
      protocol    = "HTTPS"
      status_code = "HTTP_301"   # 301 = permanent redirect
    }
  }

  tags = {
    Name = "${var.project_name}-http-listener"
  }
}