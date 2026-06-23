mock_provider "aws" {}

variables {
  zone_id = "Z0123456789ABCDEF0"
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
