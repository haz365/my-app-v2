# ═══════════════════════════════════════════════════════════════
# ECR MODULE
# Creates the Docker image registry where we push our built images
# ECS Fargate pulls from here when starting containers
# ═══════════════════════════════════════════════════════════════

# ─── ECR Repository ───────────────────────────────────────────
# This is where our Docker images live in AWS
# Think of it like Docker Hub but private and inside your AWS account
resource "aws_ecr_repository" "app" {
  name = var.project_name

  # MUTABLE = the "latest" tag can be overwritten on each push
  # Good for development — in strict production you'd use IMMUTABLE
  # so every image version is permanently preserved
  image_tag_mutability = "MUTABLE"

  # Automatically scan every pushed image for known vulnerabilities
  # Results appear in the ECR console — free service
  image_scanning_configuration {
    scan_on_push = true
  }

  tags = {
    Name = "${var.project_name}-ecr"
  }
}

# ─── Lifecycle Policy ─────────────────────────────────────────
# Automatically deletes old images to save storage costs
# Without this, every single build piles up forever
# ECR charges per GB stored so this saves money over time
resource "aws_ecr_lifecycle_policy" "app" {
  repository = aws_ecr_repository.app.name

  policy = jsonencode({
    rules = [
      {
        rulePriority = 1
        description  = "Keep only the 10 most recent images"
        selection = {
          tagStatus   = "any"       # Apply to all images regardless of tag
          countType   = "imageCountMoreThan"
          countNumber = 10          # Delete anything beyond the 10 most recent
        }
        action = {
          type = "expire"           # "expire" = delete
        }
      }
    ]
  })
}