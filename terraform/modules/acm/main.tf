# ═══════════════════════════════════════════════════════════════
# ACM MODULE
# Creates a free SSL/TLS certificate for HTTPS
# Validates ownership via DNS records added to Route 53
#
# Flow:
# 1. Request cert from ACM for yourdomain.com + *.yourdomain.com
# 2. ACM gives us a CNAME record to prove we own the domain
# 3. We add that CNAME to Route 53
# 4. ACM sees the record → validates → issues the cert
# 5. Cert is attached to the ALB HTTPS listener
# 6. Auto-renews forever — never touch it again
# ═══════════════════════════════════════════════════════════════

# ─── Request the Certificate ──────────────────────────────────
resource "aws_acm_certificate" "main" {
  # Root domain — covers yourdomain.com
  domain_name = var.domain_name

  # Wildcard covers ALL subdomains — www, api, app, etc.
  # One cert for everything under your domain
  subject_alternative_names = ["*.${var.domain_name}"]

  # DNS validation = add a CNAME record to prove domain ownership
  # Better than EMAIL validation (automated, no inbox to check)
  validation_method = "DNS"

  # Create new cert before destroying old one during updates
  # Prevents a gap where no valid cert exists
  lifecycle {
    create_before_destroy = true
  }

  tags = {
    Name = "${var.domain_name}-cert"
  }
}


# ─── Validation DNS Records ───────────────────────────────────
# ACM gives us CNAME records to add to Route 53
# Once they exist, ACM verifies them and issues the certificate
# for_each handles multiple records (one per domain in the cert)
resource "aws_route53_record" "cert_validation" {
  for_each = {
    for dvo in aws_acm_certificate.main.domain_validation_options : dvo.domain_name => {
      name   = dvo.resource_record_name
      record = dvo.resource_record_value
      type   = dvo.resource_record_type
    }
  }

  zone_id         = var.route53_zone_id
  name            = each.value.name
  type            = each.value.type
  records         = [each.value.record]
  ttl             = 60
  allow_overwrite = true
}


# ─── Wait for Validation ──────────────────────────────────────
# This resource tells Terraform to PAUSE here until ACM
# has fully validated and issued the certificate
# Without this, the HTTPS listener would try to use a
# cert that isn't ready yet and fail
resource "aws_acm_certificate_validation" "main" {
  certificate_arn = aws_acm_certificate.main.arn

  # Pass all the CNAME record FQDNs so Terraform knows
  # which records to wait for
  validation_record_fqdns = [
    for record in aws_route53_record.cert_validation : record.fqdn
  ]
}