# ═══════════════════════════════════════════════════════════════
# VPC MODULE
# Creates all networking resources:
#   - VPC
#   - 2 public subnets  (for ALB — required across 2 AZs)
#   - 1 private subnet  (for ECS Fargate tasks)
#   - Internet Gateway  (public internet access)
#   - NAT Gateway       (private subnet outbound access)
#   - Route tables      (traffic routing rules)
# ═══════════════════════════════════════════════════════════════

# ─── Availability Zones ──────────────────────────────────────
# Fetch the list of AZs available in our region
# We use [0] and [1] to pick the first two
data "aws_availability_zones" "available" {
  state = "available"
}

# ─── VPC ─────────────────────────────────────────────────────
# Our own isolated network inside AWS
# Nothing gets in or out unless we explicitly allow it
resource "aws_vpc" "main" {
  cidr_block           = var.vpc_cidr   # e.g. 10.0.0.0/16
  enable_dns_hostnames = true           # Gives instances DNS names
  enable_dns_support   = true           # Enables DNS resolution in VPC

  tags = {
    Name = "${var.project_name}-vpc"
  }
}

# ─── Public Subnets ──────────────────────────────────────────
# Two public subnets across two AZs
# Required by the ALB (it must span at least 2 AZs)
# Also where the NAT Gateway lives
resource "aws_subnet" "public_a" {
  vpc_id            = aws_vpc.main.id
  cidr_block        = "10.0.1.0/24"   # 256 IPs
  availability_zone = data.aws_availability_zones.available.names[0]

  # Anything launched here gets a public IP automatically
  # This is what makes it "public"
  map_public_ip_on_launch = true

  tags = {
    Name = "${var.project_name}-public-a"
    Tier = "public"
  }
}

resource "aws_subnet" "public_b" {
  vpc_id            = aws_vpc.main.id
  cidr_block        = "10.0.2.0/24"   # Different range, no overlap
  availability_zone = data.aws_availability_zones.available.names[1]

  map_public_ip_on_launch = true

  tags = {
    Name = "${var.project_name}-public-b"
    Tier = "public"
  }
}

# ─── Private Subnet ──────────────────────────────────────────
# One private subnet — where ECS Fargate tasks live
# No public IPs, not directly reachable from internet
resource "aws_subnet" "private" {
  vpc_id            = aws_vpc.main.id
  cidr_block        = "10.0.10.0/24"
  availability_zone = data.aws_availability_zones.available.names[0]

  # No map_public_ip_on_launch = no public IPs assigned
  # Combined with no IGW route = truly private

  tags = {
    Name = "${var.project_name}-private"
    Tier = "private"
  }
}

# ─── Internet Gateway ─────────────────────────────────────────
# The "front door" of the VPC
# Without this, nothing in the VPC can reach the internet
# and nothing from the internet can reach the VPC
resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.main.id

  tags = {
    Name = "${var.project_name}-igw"
  }
}

# ─── Elastic IP for NAT Gateway ───────────────────────────────
# NAT Gateway needs a static public IP address
# This reserves one for us
resource "aws_eip" "nat" {
  domain = "vpc"

  # Make sure IGW exists first
  # NAT needs the IGW to route outbound traffic
  depends_on = [aws_internet_gateway.igw]

  tags = {
    Name = "${var.project_name}-nat-eip"
  }
}

# ─── NAT Gateway ──────────────────────────────────────────────
# Lives in the PUBLIC subnet
# Lets private subnet resources reach the internet OUTBOUND only
# e.g. Fargate tasks pulling images from ECR, sending logs to CloudWatch
# Nothing from the internet can initiate a connection through NAT
resource "aws_nat_gateway" "nat" {
  allocation_id = aws_eip.nat.id
  subnet_id     = aws_subnet.public_a.id   # Must live in a public subnet

  depends_on = [aws_internet_gateway.igw]

  tags = {
    Name = "${var.project_name}-nat"
  }
}

# ─── Route Table: Public ───────────────────────────────────────
# Rule: send all internet-bound traffic via the IGW
# This is what makes the public subnets actually "public"
resource "aws_route_table" "public" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block = "0.0.0.0/0"                   # All internet traffic
    gateway_id = aws_internet_gateway.igw.id   # → goes via IGW
  }

  tags = {
    Name = "${var.project_name}-public-rt"
  }
}

# ─── Route Table: Private ──────────────────────────────────────
# Rule: send all internet-bound traffic via the NAT Gateway
# Outbound only — NAT won't let anything come back in unsolicited
resource "aws_route_table" "private" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.nat.id   # → goes via NAT
  }

  tags = {
    Name = "${var.project_name}-private-rt"
  }
}

# ─── Route Table Associations ─────────────────────────────────
# Without these, subnets have no route table = no routing at all
# Link each subnet to its correct route table

resource "aws_route_table_association" "public_a" {
  subnet_id      = aws_subnet.public_a.id
  route_table_id = aws_route_table.public.id
}

resource "aws_route_table_association" "public_b" {
  subnet_id      = aws_subnet.public_b.id
  route_table_id = aws_route_table.public.id
}

resource "aws_route_table_association" "private" {
  subnet_id      = aws_subnet.private.id
  route_table_id = aws_route_table.private.id
}