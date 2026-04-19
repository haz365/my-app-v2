# ═══════════════════════════════════════════════════════════════
# ROUTE 53 MODULE — OUTPUTS
# ═══════════════════════════════════════════════════════════════

output "zone_id" {
  description = "Hosted zone ID — needed by ACM to add validation records"
  value       = aws_route53_zone.main.zone_id
}

output "nameservers" {
  description = "4 nameservers to paste into GoDaddy custom nameservers"
  value       = aws_route53_zone.main.name_servers
}