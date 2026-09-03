
output "zone_id" {
  description = "The ID of the Route 53 hosted zone"
  value       = aws_route53_zone.public.zone_id
}

output "name_servers" {
  description = "List of name servers for delegation"
  value       = aws_route53_zone.public.name_servers
}

output "additional_zone_ids" {
  description = "Map of additional internal domain name => its public hosted zone ID (used for ACM DNS validation)."
  value = try({
    for k, v in aws_route53_zone.additional_public : k => v.zone_id
  }, null)
}

output "additional_name_servers" {
  description = "Map of additional internal domain name => that public zone's name servers (used for delegation)."
  value = try({
    for k, v in aws_route53_zone.additional_public : k => v.name_servers
  }, null)
}
