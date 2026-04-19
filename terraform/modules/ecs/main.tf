# ═══════════════════════════════════════════════════════════════
# ECS MODULE
# Creates everything needed to run containers on Fargate:
#
# 1. CLOUDWATCH LOG GROUP — where container logs go
# 2. ECS CLUSTER — logical grouping of compute
# 3. TASK DEFINITION — blueprint for the container
# 4. ECS SERVICE — keeps N tasks running at all times
# 5. HTTPS LISTENER — port 443 on the ALB with our SSL cert
# ═══════════════════════════════════════════════════════════════


# ─── CloudWatch Log Group ─────────────────────────────────────
# Every console.log() in server.js ends up here
# Without this, you have no visibility into what your app is doing
resource "aws_cloudwatch_log_group" "app" {
  name = "/ecs/${var.project_name}"

  # Auto-delete logs older than 7 days to save money
  # CloudWatch charges per GB stored
  retention_in_days = 7

  tags = {
    Name = "${var.project_name}-logs"
  }
}


# ─── ECS Cluster ──────────────────────────────────────────────
# A logical container for ECS services and tasks
# With Fargate, this is basically just a name
# AWS manages all the underlying compute — no servers to manage
resource "aws_ecs_cluster" "main" {
  name = "${var.project_name}-cluster"

  setting {
    name  = "containerInsights"
    value = "disabled"   # Enable for production monitoring
  }

  tags = {
    Name = "${var.project_name}-cluster"
  }
}


# ─── ECS Cluster Capacity Provider ───────────────────────────
# Tells the cluster to use Fargate (serverless) compute
resource "aws_ecs_cluster_capacity_providers" "main" {
  cluster_name       = aws_ecs_cluster.main.name
  capacity_providers = ["FARGATE"]

  default_capacity_provider_strategy {
    capacity_provider = "FARGATE"
    base              = 1     # Always have at least 1 task on Fargate
    weight            = 100
  }
}


# ─── ECS Task Definition ──────────────────────────────────────
# The blueprint for running ONE instance of our container
# Defines: image, CPU, memory, ports, env vars, logging, IAM roles
resource "aws_ecs_task_definition" "app" {
  family = var.project_name   # Groups revisions together

  # awsvpc = each task gets its own network interface
  # Required for Fargate
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]

  # Smallest Fargate size — cheapest option
  # 256 CPU units = 0.25 vCPU
  # 512 MB memory
  cpu    = "256"
  memory = "512"

  # Role ECS uses to START the container (pull image, write logs)
  execution_role_arn = var.task_execution_role_arn

  # Role your APP CODE uses at runtime (DynamoDB access)
  task_role_arn = var.task_role_arn

  # Container definition — JSON describing our container
  container_definitions = jsonencode([
    {
      # Must match the container_name in the service's load_balancer block
      name  = var.project_name
      image = "${var.ecr_repository_url}:latest"

      # Essential = if this container dies, restart the whole task
      essential = true

      # Map container port to host port
      portMappings = [
        {
          containerPort = var.container_port
          hostPort      = var.container_port
          protocol      = "tcp"
        }
      ]

      # Environment variables — read by server.js via process.env
      # These override the defaults set in server.js
      environment = [
        {
          name  = "PORT"
          value = tostring(var.container_port)
        },
        {
          name  = "AWS_REGION"
          value = var.region
        },
        {
          name  = "DYNAMO_TABLE"
          value = var.dynamodb_table_name
        }
      ]

      # Send container stdout/stderr to CloudWatch
      # Every console.log() appears here
      logConfiguration = {
        logDriver = "awslogs"
        options = {
          "awslogs-group"         = aws_cloudwatch_log_group.app.name
          "awslogs-region"        = var.region
          "awslogs-stream-prefix" = "ecs"
        }
      }

      # Container-level health check
      # Separate from the ALB health check
      # ECS uses this to decide if the container itself is healthy
      healthCheck = {
        command     = ["CMD-SHELL", "wget -qO- http://localhost:${var.container_port}/health || exit 1"]
        interval    = 30
        timeout     = 5
        retries     = 3
        startPeriod = 10   # Grace period before checks start counting
      }
    }
  ])

  tags = {
    Name = "${var.project_name}-task-def"
  }
}


# ─── HTTPS Listener ───────────────────────────────────────────
# We create this here because it needs the ACM cert ARN
# which comes from the ACM module
# Port 443 with our SSL cert — the secure entry point
resource "aws_lb_listener" "https" {
  load_balancer_arn = var.alb_arn
  port              = 443
  protocol          = "HTTPS"

  # Modern TLS policy — supports TLS 1.2 and 1.3
  ssl_policy      = "ELBSecurityPolicy-TLS13-1-2-2021-06"
  certificate_arn = var.certificate_arn

  default_action {
    type             = "forward"
    target_group_arn = var.target_group_arn
  }

  tags = {
    Name = "${var.project_name}-https-listener"
  }
}


# ─── ECS Service ──────────────────────────────────────────────
# Keeps N copies of the task running at all times
# If a task crashes, ECS automatically starts a replacement
# Integrates with the ALB to register/deregister tasks
resource "aws_ecs_service" "app" {
  name            = "${var.project_name}-service"
  cluster         = aws_ecs_cluster.main.id
  task_definition = aws_ecs_task_definition.app.arn
  desired_count   = var.desired_count
  launch_type     = "FARGATE"

  # Grace period before ALB health checks count
  # Gives Node.js time to start before being killed for failing checks
  health_check_grace_period_seconds = 30

  # ── Networking ─────────────────────────────────────────────
  network_configuration {
    subnets          = [var.private_subnet_id]   # Private subnet only
    security_groups  = [var.ecs_sg_id]           # Only ALB can reach us
    assign_public_ip = false                      # No public IP needed
  }

  # ── Load Balancer Integration ──────────────────────────────
  # ECS auto-registers task IPs with the target group on startup
  # and deregisters them on shutdown
  load_balancer {
    target_group_arn = var.target_group_arn
    container_name   = var.project_name   # Must match container name above
    container_port   = var.container_port
  }

  # ── Deployment Settings ────────────────────────────────────
  # During a rolling deploy:
  # - Never go below 100% of desired tasks (no downtime)
  # - Can temporarily run up to 200% (old + new tasks simultaneously)
  deployment_minimum_healthy_percent = 100
  deployment_maximum_percent         = 200

  # Wait for both the HTTP and HTTPS listeners to exist
  # before creating the service
  depends_on = [
    var.alb_listener_arn,
    aws_lb_listener.https
  ]

  # Ignore external changes to desired_count
  # Useful if you later add auto-scaling without Terraform resetting it
  lifecycle {
    ignore_changes = [desired_count]
  }

  tags = {
    Name = "${var.project_name}-service"
  }
}