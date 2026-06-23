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
