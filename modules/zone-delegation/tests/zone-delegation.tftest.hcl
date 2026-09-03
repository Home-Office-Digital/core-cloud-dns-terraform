mock_provider "aws" {}

variables {
  zone_id     = "Z0123456789ABCDEF0"
  domain_name = "service.example.gov.uk"
  workload_public_zone_ns_records = [
    "ns-111.awsdns-11.org.",
    "ns-222.awsdns-22.net.",
    "ns-333.awsdns-33.co.uk.",
    "ns-444.awsdns-44.com."
  ]
}

run "plan_zone_delegation" {
  command = plan

  assert {
    condition     = aws_route53_record.ns_record.type == "NS"
    error_message = "Delegation record type must be NS."
  }

  assert {
    condition     = aws_route53_record.ns_record.zone_id == var.zone_id
    error_message = "Delegation record should be created in the supplied parent zone ID."
  }

  assert {
    condition     = aws_route53_record.ns_record.name == var.domain_name
    error_message = "Delegation record name should match the delegated domain."
  }

  assert {
    condition     = toset(aws_route53_record.ns_record.records) == toset(var.workload_public_zone_ns_records)
    error_message = "Delegation record should use the supplied NS records."
  }

  assert {
    condition     = aws_route53_record.ns_record.ttl == 300
    error_message = "Delegation record TTL should remain 300 seconds."
  }

  assert {
    condition     = length(aws_route53_record.ns_record.records) == 4
    error_message = "Delegation record should include four nameservers in the default test case."
  }
}

run "plan_zone_delegation_with_module_default_ns_records" {
  command = plan

  variables {
    workload_public_zone_ns_records = [
      "ns-1234.awsdns-33.org.",
      "ns-1234.awsdns-15.net.",
      "ns-1234.awsdns-25.co.uk.",
      "ns-1234.awsdns-45.com."
    ]
  }

  assert {
    condition     = contains(aws_route53_record.ns_record.records, "ns-1234.awsdns-33.org.")
    error_message = "Delegation record should support the module default-style nameserver values."
  }

  assert {
    condition     = aws_route53_record.ns_record.type == "NS"
    error_message = "Record type should stay NS in default-style nameserver scenario."
  }
}

run "plan_additional_domain_delegations" {
  command = plan

  variables {
    # Map of additional child domain => that domain's OWN name servers,
    # mirroring the r53-public-zone module's additional_name_servers output.
    additional_name_servers = {
      "extra1.example.gov.uk" = [
        "ns-11.awsdns-11.org.",
        "ns-12.awsdns-12.net.",
      ]
      "extra2.example.gov.uk" = [
        "ns-21.awsdns-21.org.",
        "ns-22.awsdns-22.net.",
        "ns-23.awsdns-23.co.uk.",
      ]
    }
  }

  # One NS delegation record per additional domain, keyed by domain.
  assert {
    condition     = length(aws_route53_record.additional_ns_records) == 2
    error_message = "One additional NS delegation record should be created per additional domain."
  }

  assert {
    condition     = aws_route53_record.additional_ns_records["extra1.example.gov.uk"].name == "extra1.example.gov.uk"
    error_message = "Additional delegation record name should match the additional domain."
  }

  assert {
    condition     = aws_route53_record.additional_ns_records["extra1.example.gov.uk"].type == "NS"
    error_message = "Additional delegation record type must be NS."
  }

  assert {
    condition     = aws_route53_record.additional_ns_records["extra2.example.gov.uk"].ttl == 300
    error_message = "Additional delegation record TTL should remain 300 seconds."
  }

  # Each additional delegation is created in the SAME parent zone as the primary.
  assert {
    condition     = aws_route53_record.additional_ns_records["extra1.example.gov.uk"].zone_id == var.zone_id
    error_message = "Additional delegation record should be created in the shared parent zone."
  }

  # Each additional record uses its OWN name servers, not the primary's set.
  assert {
    condition     = toset(aws_route53_record.additional_ns_records["extra1.example.gov.uk"].records) == toset(var.additional_name_servers["extra1.example.gov.uk"])
    error_message = "Additional delegation record should use that domain's own NS records."
  }

  assert {
    condition     = length(aws_route53_record.additional_ns_records["extra2.example.gov.uk"].records) == 3
    error_message = "Second additional domain should carry its own three NS records, independent of the first."
  }

  # The primary delegation record is unaffected by the additional-domains path.
  assert {
    condition     = aws_route53_record.ns_record.name == var.domain_name
    error_message = "Primary delegation record should still target the primary domain."
  }
}

run "plan_no_additional_delegations_by_default" {
  command = plan

  assert {
    condition     = length(aws_route53_record.additional_ns_records) == 0
    error_message = "No additional delegation records should be created when the list is empty (default)."
  }
}
