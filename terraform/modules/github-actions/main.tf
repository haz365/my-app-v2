# ═══════════════════════════════════════════════════════════════
# GITHUB ACTIONS MODULE
# Sets up OIDC so GitHub Actions can securely authenticate
# to AWS without long-lived credentials
#
# Creates:
# 1. OIDC Identity Provider — AWS trusts GitHub's tokens
# 2. IAM Role — what GitHub Actions is allowed to do
# 3. IAM Policy — specific permissions for the role
# ═══════════════════════════════════════════════════════════════

# ─── OIDC Identity Provider ───────────────────────────────────
# Registers GitHub as a trusted identity provider in AWS
# This is what allows AWS to verify tokens from GitHub Actions
# Only needs to be created once per AWS account
resource "aws_iam_openid_connect_provider" "github" {
  # GitHub's OIDC provider URL — this is fixed, never changes
  url = "https://token.actions.githubusercontent.com"

  # The audience GitHub Actions uses when requesting tokens
  client_id_list = ["sts.amazonaws.com"]

  # GitHub's OIDC thumbprint — identifies GitHub's certificate
  # This is a fixed value for GitHub Actions
  thumbprint_list = ["6938fd4d98bab03faadb97b34396831e3780aea1"]
}


# ─── IAM Role for GitHub Actions ──────────────────────────────
# This is the role GitHub Actions will assume during each run
# The trust policy restricts it to YOUR specific repo only
# (not just any GitHub repo — scoped to yours)
resource "aws_iam_role" "github_actions" {
  name = "${var.project_name}-github-actions-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect    = "Allow"
      Action    = "sts:AssumeRoleWithWebIdentity"
      Principal = {
        # Reference the OIDC provider we just created
        Federated = aws_iam_openid_connect_provider.github.arn
      }
      Condition = {
        StringEquals = {
          # Only tokens for YOUR specific repo can assume this role
          # Format: repo:GITHUB_ORG/REPO_NAME:*
          "token.actions.githubusercontent.com:aud" = "sts.amazonaws.com"
        }
        StringLike = {
          # Allow any branch/tag/PR in your repo to trigger this
          # Change "ref:refs/heads/main" to restrict to main branch only
          "token.actions.githubusercontent.com:sub" = "repo:${var.github_org}/${var.github_repo}:*"
        }
      }
    }]
  })

  tags = {
    Name = "${var.project_name}-github-actions-role"
  }
}


# ─── IAM Policy for GitHub Actions ────────────────────────────
# Exactly what GitHub Actions needs — nothing more, nothing less:
# - Push Docker images to ECR
# - Force new ECS deployments
# - Pass IAM roles to ECS (required for task definitions)
resource "aws_iam_role_policy" "github_actions" {
  name = "${var.project_name}-github-actions-policy"
  role = aws_iam_role.github_actions.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        # Authenticate Docker with ECR
        # Required before any docker push
        Sid    = "ECRAuth"
        Effect = "Allow"
        Action = [
          "ecr:GetAuthorizationToken"
        ]
        Resource = "*"   # This specific action requires * (AWS limitation)
      },
      {
        # Push Docker images to our specific ECR repository
        Sid    = "ECRPush"
        Effect = "Allow"
        Action = [
          "ecr:BatchCheckLayerAvailability",
          "ecr:CompleteLayerUpload",
          "ecr:InitiateLayerUpload",
          "ecr:PutImage",
          "ecr:UploadLayerPart",
          "ecr:BatchGetImage",
          "ecr:GetDownloadUrlForLayer"
        ]
        # Scoped to ONLY our ECR repository
        Resource = var.ecr_repository_arn
      },
      {
        # Trigger new ECS deployments
        Sid    = "ECSDeployment"
        Effect = "Allow"
        Action = [
          "ecs:UpdateService",           # Force new deployment
          "ecs:DescribeServices",        # Check deployment status
          "ecs:DescribeTaskDefinition",  # Read current task def
          "ecs:RegisterTaskDefinition"   # Register new task def with new image
        ]
        Resource = "*"
      },
      {
        # Required when registering a new task definition
        # ECS needs to pass the IAM roles to the new task
        Sid    = "IAMPassRole"
        Effect = "Allow"
        Action = "iam:PassRole"
        Resource = "*"
        Condition = {
          StringEquals = {
            "iam:PassedToService" = "ecs-tasks.amazonaws.com"
          }
        }
      }
    ]
  })
}