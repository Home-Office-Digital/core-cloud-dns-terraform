output "zone_id" {
  description = "The ID of the Route 53 hosted zone"
  value       = aws_route53_zone.workload_zone.zone_id
}

output "name_servers" {
  description = "List of name servers for delegation"
  value       = aws_route53_zone.workload_zone.name_servers
}

output "dnssec_ds_record" {
  value       = var.enable_dnssec ? aws_route53_key_signing_key.ksk[0].ds_record : null
  description = "DS record to add at your domain registrar when DNSSEC is enabled"
}

output "additional_zone_ids" {
  description = "Map of additional domain name => its public hosted zone ID."
  value = try({
    for k, v in aws_route53_zone.additional_workload_zones : k => v.zone_id
  }, null)
}

output "additional_name_servers" {
  description = "Map of additional domain name => that zone's name servers (used for delegation)."
  value = try({
    for k, v in aws_route53_zone.additional_workload_zones : k => v.name_servers
  }, null)
}

output "additional_dnssec_ds_record" {
  description = "Map of additional domain name => DS record for the registrar, when DNSSEC is enabled (null otherwise)."
  value = var.enable_dnssec ? try({
    for k, v in aws_route53_key_signing_key.additional_ksks : k => v.ds_record
  }, null) : null
}
