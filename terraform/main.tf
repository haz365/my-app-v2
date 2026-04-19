# ═══════════════════════════════════════════════════════════════
# ROOT MAIN.TF
# Wires all modules together
# Each module is called here and outputs are passed between them
# ═══════════════════════════════════════════════════════════════

# ─── VPC ─────────────────────────────────────────────────────
# Creates all networking: VPC, subnets, IGW, NAT, route tables
module "vpc" {
  source       = "./modules/vpc"
  project_name = var.project_name
  vpc_cidr     = var.vpc_cidr
}

# ─── ECR ─────────────────────────────────────────────────────
# Creates the Docker image registry
module "ecr" {
  source       = "./modules/ecr"
  project_name = var.project_name
}

# ─── DATABASE ────────────────────────────────────────────────
# Creates the DynamoDB visit counter table
module "database" {
  source       = "./modules/database"
  project_name = var.project_name
}

# ─── IAM ─────────────────────────────────────────────────────
# Creates task execution role and task role
# Needs database ARN to scope DynamoDB permissions correctly
module "iam" {
  source             = "./modules/iam"
  project_name       = var.project_name
  dynamodb_table_arn = module.database.table_arn   # ← from database module
}

# ─── SECURITY ────────────────────────────────────────────────
# Creates security groups for ALB and ECS
# Needs vpc_id from the VPC module
module "security" {
  source         = "./modules/security"
  project_name   = var.project_name
  vpc_id         = module.vpc.vpc_id          # ← from vpc module
  container_port = var.container_port
}

# ─── ALB ─────────────────────────────────────────────────────
# Creates load balancer, target group, HTTP listener
# Needs public subnet IDs and ALB security group from other modules
module "alb" {
  source            = "./modules/alb"
  project_name      = var.project_name
  vpc_id            = module.vpc.vpc_id
  public_subnet_ids = module.vpc.public_subnet_ids   # ← from vpc module
  alb_sg_id         = module.security.alb_sg_id      # ← from security module
  container_port    = var.container_port
}

# ─── ROUTE 53 ────────────────────────────────────────────────
# Creates hosted zone and DNS records pointing to ALB
# Must be created BEFORE ACM (ACM needs the zone ID)
module "route53" {
  source       = "./modules/route53"
  domain_name  = var.domain_name
  alb_dns_name = module.alb.alb_dns_name   # ← from alb module
  alb_zone_id  = module.alb.alb_zone_id    # ← from alb module
}

# ─── ACM ─────────────────────────────────────────────────────
# Creates SSL certificate + validates via Route 53
# Must come AFTER route53 (needs zone ID)
module "acm" {
  source          = "./modules/acm"
  domain_name     = var.domain_name
  route53_zone_id = module.route53.zone_id   # ← from route53 module
}

# ─── ECS ─────────────────────────────────────────────────────
# Creates cluster, task definition, service, HTTPS listener
# Pulls from almost every other module
module "ecs" {
  source = "./modules/ecs"

  project_name       = var.project_name
  region             = var.region
  container_port     = var.container_port
  desired_count      = var.desired_count

  # From ECR module
  ecr_repository_url = module.ecr.repository_url

  # From VPC module
  private_subnet_id  = module.vpc.private_subnet_id

  # From security module
  ecs_sg_id          = module.security.ecs_sg_id

  # From ALB module
  target_group_arn   = module.alb.target_group_arn
  alb_arn            = module.alb.alb_arn
  alb_listener_arn   = module.alb.http_listener_arn

  # From IAM module
  task_execution_role_arn = module.iam.task_execution_role_arn
  task_role_arn           = module.iam.task_role_arn

  # From database module
  dynamodb_table_name = module.database.table_name

  # From ACM module
  certificate_arn    = module.acm.certificate_arn
}

# ─── GITHUB ACTIONS ──────────────────────────────────────────
# Sets up OIDC so GitHub Actions can authenticate to AWS
# without long-lived credentials
module "github_actions" {
  source = "./modules/github-actions"

  project_name       = var.project_name
  github_org         = var.github_org
  github_repo        = var.github_repo
  ecr_repository_arn = module.ecr.repository_arn   # ← changed from repository_url
  ecs_cluster_name   = module.ecs.cluster_name
  ecs_service_name   = module.ecs.service_name
}