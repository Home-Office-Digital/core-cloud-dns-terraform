
resource "aws_route53_record" "ns_record" {
  zone_id = var.zone_id
  name    = var.domain_name
  type    = "NS"
  ttl     = 300
  records = var.workload_public_zone_ns_records
}

# For additional domains: delegate each child domain to its OWN name servers.
# Each record is created in its per-domain parent zone from additional_zone_ids
# when provided, otherwise it falls back to the primary parent zone (var.zone_id).
resource "aws_route53_record" "additional_ns_records" {
  for_each = try(var.additional_name_servers, {})
  zone_id  = try(var.additional_zone_ids[each.key], var.zone_id)
  name     = each.key
  type     = "NS"
  ttl      = 300
  records  = each.value
}
