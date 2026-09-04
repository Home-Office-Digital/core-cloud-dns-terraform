mock_provider "aws" {}

variables {
  internal_domain_name = "np.internal.example.gov.uk"
  internal_zone_id     = "Z0123456789ABCDEF0"
  tags = {
    Owner = "platform"
  }
}

run "plan_internal_dns_cert" {
  command = plan

  assert {
    condition     = aws_acm_certificate.wildcard.domain_name == "*.${var.internal_domain_name}"
    error_message = "Wildcard certificate should use the module domain."
  }

  assert {
    condition     = aws_route53_record.wildcard_validation.zone_id == var.internal_zone_id
    error_message = "Validation record should be created in the provided zone ID."
  }

  assert {
    condition     = aws_route53_record.wildcard_validation.ttl == 60
    error_message = "Validation record TTL should remain 60 seconds."
  }

  assert {
    condition     = aws_acm_certificate.wildcard.validation_method == "DNS"
    error_message = "Wildcard certificate should use DNS validation."
  }

  assert {
    condition     = aws_acm_certificate.wildcard.tags["Component"] == "internal-dns-cert"
    error_message = "Certificate tags should include the internal-dns-cert component marker."
  }

  assert {
    condition     = aws_acm_certificate.wildcard.tags["Owner"] == "platform"
    error_message = "Certificate should preserve user-supplied tags."
  }
}

run "plan_internal_dns_cert_without_user_tags" {
  command = plan

  variables {
    tags = {}
  }

  assert {
    condition     = aws_acm_certificate.wildcard.domain_name == "*.${var.internal_domain_name}"
    error_message = "Wildcard domain should remain unchanged when no user tags are provided."
  }

  assert {
    condition     = aws_acm_certificate.wildcard.tags["Environment"] == "prod"
    error_message = "Default Environment tag should be present when user tags are omitted."
  }
}

run "plan_additional_internal_domains" {
  command = plan

  variables {
    additional_internal_zone_ids = {
      "extra1.np.internal.example.gov.uk" = "Z0EXTRA1111111111"
      "extra2.np.internal.example.gov.uk" = "Z0EXTRA2222222222"
    }
  }

  # The cert must be keyed by DOMAIN (map key), not by zone ID (map value).
  assert {
    condition     = aws_acm_certificate.additional_wildcards["extra1.np.internal.example.gov.uk"].domain_name == "*.extra1.np.internal.example.gov.uk"
    error_message = "Additional wildcard cert should use the domain (map key), not the zone ID."
  }

  # The validation record must land in the domain's PUBLIC hosted zone.
  assert {
    condition     = aws_route53_record.additional_wildcard_validations["extra1.np.internal.example.gov.uk"].zone_id == "Z0EXTRA1111111111"
    error_message = "Validation record should be created in the domain's public zone ID."
  }

  assert {
    condition     = aws_route53_record.additional_wildcard_validations["extra2.np.internal.example.gov.uk"].zone_id == "Z0EXTRA2222222222"
    error_message = "Second additional validation record should use its own public zone ID."
  }

  # One cert + validation record + validation per additional domain.
  assert {
    condition     = length(aws_acm_certificate.additional_wildcards) == 2
    error_message = "One additional wildcard cert should be created per entry in the zone-id map."
  }

  assert {
    condition     = length(aws_acm_certificate_validation.additional_wildcards) == 2
    error_message = "One additional cert validation should be created per entry in the zone-id map."
  }
}

run "plan_no_additional_internal_domains_by_default" {
  command = plan

  # With no additional_internal_zone_ids supplied, none of the additional
  # cert resources should be created, and the primary cert is unaffected.
  assert {
    condition     = length(aws_acm_certificate.additional_wildcards) == 0
    error_message = "No additional wildcard certs should be created when the map is empty (default)."
  }

  assert {
    condition     = length(aws_route53_record.additional_wildcard_validations) == 0
    error_message = "No additional validation records should be created when the map is empty (default)."
  }

  assert {
    condition     = length(aws_acm_certificate_validation.additional_wildcards) == 0
    error_message = "No additional cert validations should be created when the map is empty (default)."
  }

  assert {
    condition     = aws_acm_certificate.wildcard.domain_name == "*.${var.internal_domain_name}"
    error_message = "Primary wildcard cert should be unaffected by the additional-domains path."
  }
}
