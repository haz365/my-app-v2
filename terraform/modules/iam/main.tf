# ═══════════════════════════════════════════════════════════════
# IAM MODULE
# Creates two IAM roles for ECS Fargate:
#
# 1. TASK EXECUTION ROLE
#    Used by ECS itself to bootstrap the container:
#    - Pull the Docker image from ECR
#    - Send container logs to CloudWatch
#    Your app code never uses this role directly
#
# 2. TASK ROLE
#    Used by your running app code at runtime:
#    - Read/write DynamoDB visit counter table
#    The AWS SDK auto-detects this via Fargate's metadata service
#    No hardcoded credentials ever needed
# ═══════════════════════════════════════════════════════════════


# ─── Task Execution Role ──────────────────────────────────────

# The role itself — defines WHO can assume it
# "ecs-tasks.amazonaws.com" means ECS tasks can become this role
resource "aws_iam_role" "task_execution" {
  name = "${var.project_name}-task-execution-role"

  # Trust policy: which AWS service can assume this role
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action    = "sts:AssumeRole"
      Effect    = "Allow"
      Principal = {
        Service = "ecs-tasks.amazonaws.com"
      }
    }]
  })

  tags = {
    Name = "${var.project_name}-task-execution-role"
  }
}

# Attach the AWS managed policy for ECS task execution
# This pre-built policy grants exactly what ECS needs to start containers:
#   - ecr:GetAuthorizationToken
#   - ecr:BatchPullImage
#   - logs:CreateLogStream
#   - logs:PutLogEvents
# AWS maintains this policy — we just link our role to it
resource "aws_iam_role_policy_attachment" "task_execution" {
  role       = aws_iam_role.task_execution.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
}


# ─── Task Role ────────────────────────────────────────────────

# The role your APPLICATION CODE uses at runtime
# When server.js calls DynamoDB, this role's permissions apply
resource "aws_iam_role" "task" {
  name = "${var.project_name}-task-role"

  # Same trust policy — ECS tasks can assume this role too
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action    = "sts:AssumeRole"
      Effect    = "Allow"
      Principal = {
        Service = "ecs-tasks.amazonaws.com"
      }
    }]
  })

  tags = {
    Name = "${var.project_name}-task-role"
  }
}

# Custom policy: exactly what our app needs and nothing more
# This is "least privilege" — scope permissions as tightly as possible
# If the app is compromised, the attacker can ONLY touch this one table
resource "aws_iam_role_policy" "task_dynamodb" {
  name = "${var.project_name}-task-dynamodb-policy"
  role = aws_iam_role.task.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect = "Allow"
      Action = [
        "dynamodb:UpdateItem",   # Increment the visit counter
        "dynamodb:GetItem",      # Read the current count
        "dynamodb:PutItem"       # Create the item if it doesn't exist
      ]
      # Scoped to ONLY our specific table — not all DynamoDB tables
      Resource = var.dynamodb_table_arn
    }]
  })
}