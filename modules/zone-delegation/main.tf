
resource "aws_route53_record" "ns_record" {
  zone_id = var.zone_id
  name    = var.domain_name
  type    = "NS"
  ttl     = 300
  records = var.workload_public_zone_ns_records
}

# For additional domains: delegate each child domain to its OWN name servers,
# creating the NS record in the same parent zone as the primary delegation.
resource "aws_route53_record" "additional_ns_records" {
  for_each = try(var.additional_name_servers, {})
  zone_id  = var.zone_id
  name     = each.key
  type     = "NS"
  ttl      = 300
  records  = each.value
}
