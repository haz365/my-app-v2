# ═══════════════════════════════════════════════════════════════
# ACM MODULE — INPUTS
# ═══════════════════════════════════════════════════════════════

variable "domain_name" {
  description = "Root domain e.g. mydomain.com"
  type        = string
}

variable "route53_zone_id" {
  description = "Route 53 hosted zone ID — needed to add validation records"
  type        = string
}