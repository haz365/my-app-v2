# ═══════════════════════════════════════════════════════════════
# ROUTE 53 MODULE
# Creates:
# 1. Hosted zone — the DNS container for your domain
# 2. A record — maps yourdomain.com → ALB
# 3. www A record — maps www.yourdomain.com → ALB
#
# After terraform apply you'll take the 4 nameservers
# from the output and paste them into GoDaddy
# ═══════════════════════════════════════════════════════════════

# ─── Hosted Zone ──────────────────────────────────────────────
# A hosted zone is the container for all DNS records of a domain
# Once you point GoDaddy's nameservers here, AWS handles all DNS
resource "aws_route53_zone" "main" {
  name = var.domain_name

  tags = {
    Name = "${var.domain_name}-zone"
  }
}


# ─── A Record — Apex domain ───────────────────────────────────
# Maps yourdomain.com → ALB
# Using "alias" instead of a regular A record because:
# - ALB IPs change dynamically (AWS scales it)
# - Alias auto-follows IP changes
# - Alias is free (regular A records charge per query)
resource "aws_route53_record" "apex" {
  zone_id = aws_route53_zone.main.zone_id
  name    = var.domain_name
  type    = "A"

  alias {
    name                   = var.alb_dns_name
    zone_id                = var.alb_zone_id
    evaluate_target_health = true   # Stop routing if ALB is unhealthy
  }
}


# ─── A Record — www subdomain ─────────────────────────────────
# Maps www.yourdomain.com → same ALB
resource "aws_route53_record" "www" {
  zone_id = aws_route53_zone.main.zone_id
  name    = "www.${var.domain_name}"
  type    = "A"

  alias {
    name                   = var.alb_dns_name
    zone_id                = var.alb_zone_id
    evaluate_target_health = true
  }
}