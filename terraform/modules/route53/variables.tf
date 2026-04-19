# ═══════════════════════════════════════════════════════════════
# ROUTE 53 MODULE — INPUTS
# ═══════════════════════════════════════════════════════════════

variable "domain_name" {
  description = "Root domain e.g. mydomain.com"
  type        = string
}

variable "alb_dns_name" {
  description = "ALB DNS name — the A record points here"
  type        = string
}

variable "alb_zone_id" {
  description = "ALB hosted zone ID — required for alias records"
  type        = string
}