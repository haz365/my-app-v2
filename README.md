## 🚀 Getting Started

### Prerequisites

- [Node.js 20+](https://nodejs.org/)
- [Docker Desktop](https://www.docker.com/products/docker-desktop/)
- [Terraform 1.5+](https://www.terraform.io/)
- [AWS CLI](https://aws.amazon.com/cli/) configured with your credentials

### Run locally

```bash
cd app
npm install
npm start
```

Open [http://localhost:3000](http://localhost:3000)

> Note: The visit counter shows an error locally (no DynamoDB).
> `/health` works fine.

### Run tests

```bash
cd app
npm test
```

## 🏗️ Deploy to AWS

### Step 1: Bootstrap Terraform backend

Create these manually once in your AWS account:

- S3 bucket for Terraform state (versioning enabled, public access blocked)
- DynamoDB table for state locking (partition key: `LockID`)

Update `terraform/backend.tf` with your bucket name and table name.

### Step 2: Deploy Route 53 first

```bash
cd terraform
terraform init

terraform apply \
  -target=module.route53 \
  -var="github_org=YOUR_GITHUB_USERNAME" \
  -var="github_repo=YOUR_REPO_NAME"

terraform output route53_nameservers
```

Paste the 4 nameservers into your domain registrar.

### Step 3: Wait for DNS propagation

```bash
watch -n 30 "dig NS yourdomain.com +short"
```

### Step 4: Deploy everything

```bash
terraform apply \
  -var="github_org=YOUR_GITHUB_USERNAME" \
  -var="github_repo=YOUR_REPO_NAME"
```

### Step 5: Push Docker image

```bash
# Authenticate with ECR
aws ecr get-login-password --region YOUR_REGION | \
  docker login --username AWS --password-stdin \
  YOUR_ECR_URL

# Build for linux/amd64 (required for Fargate)
docker build --platform linux/amd64 -t my-app-v2 .

# Tag and push
docker tag my-app-v2:latest YOUR_ECR_URL:latest
docker push YOUR_ECR_URL:latest
```

### Step 6: Force new ECS deployment

```bash
aws ecs update-service \
  --cluster YOUR_CLUSTER_NAME \
  --service YOUR_SERVICE_NAME \
  --force-new-deployment \
  --region YOUR_REGION
```

## 🗑️ Destroy infrastructure

### Destroy app only (keeps OIDC + GitHub Actions role)

```bash
cd terraform
terraform destroy \
  -target=module.ecs \
  -target=module.alb \
  -target=module.acm \
  -target=module.route53 \
  -target=module.security \
  -target=module.iam \
  -target=module.database \
  -target=module.ecr \
  -target=module.vpc \
  -var="github_org=YOUR_GITHUB_USERNAME" \
  -var="github_repo=YOUR_REPO_NAME"
```

### Destroy everything

```bash
terraform destroy \
  -var="github_org=YOUR_GITHUB_USERNAME" \
  -var="github_repo=YOUR_REPO_NAME"
```

## 🔐 Security

- **OIDC** — GitHub Actions authenticates to AWS without long-lived credentials
- **IAM least privilege** — each role has only the permissions it needs
- **Private subnets** — ECS tasks are not directly reachable from the internet
- **Security groups** — ECS only accepts traffic from the ALB
- **No hardcoded credentials** — AWS SDK auto-discovers credentials via IAM roles

## 🧰 Tech Stack

| Layer | Technology |
|---|---|
| App | Node.js + Express |
| Container | Docker (multi-stage, Alpine) |
| Registry | Amazon ECR |
| Compute | AWS ECS Fargate |
| Database | Amazon DynamoDB |
| Networking | AWS VPC, ALB, Route 53 |
| SSL | AWS ACM |
| IaC | Terraform (modular) |
| State | S3 + DynamoDB locking |
| CI | GitHub Actions |
| Auth | OIDC (no secrets) |
| Logs | CloudWatch |