# ═══════════════════════════════════════════════════════════════
# TERRAFORM CONFIGURATION
# Defines the required Terraform version, providers, and backend
# ═══════════════════════════════════════════════════════════════

terraform {

  # Minimum Terraform version required
  # Prevents older versions from running this code
  required_version = ">= 1.5.0"

  # Providers are plugins that let Terraform talk to external services
  # "hashicorp/aws" is the official AWS provider
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"   # Any 5.x version
    }
  }

  # ─── Remote Backend ──────────────────────────────────────
  # Instead of storing state locally (terraform.tfstate file),
  # we store it in S3 so it's:
  #   - Safe (versioned, encrypted)
  #   - Shared (team members all see the same state)
  #   - Backed up (S3 is 99.999999999% durable)
  backend "s3" {
    # The S3 bucket we created manually (bootstrap step)
    bucket = "terraform-state-989346120260"

    # Path inside the bucket where the state file lives
    # Having a project-specific key means one bucket can hold
    # state for multiple projects
    key = "my-app-v2/terraform.tfstate"

    # Region where the S3 bucket lives
    region = "eu-west-2"

    # DynamoDB table for state locking
    # Prevents two people running terraform apply simultaneously
    dynamodb_table = "terraform-locks"

    # Encrypt the state file at rest in S3
    # State files can contain sensitive values (IPs, ARNs, etc.)
    encrypt = true
  }
}

# ─── AWS Provider Configuration ──────────────────────────────
# Tells the AWS provider which region to deploy resources into
# var.region comes from terraform/variables.tf
provider "aws" {
  region = var.region
}