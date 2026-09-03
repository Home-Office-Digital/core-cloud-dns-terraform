mock_provider "aws" {}

variables {
  domain_name   = "service.example.gov.uk"
  environment   = "nonprod"
  enable_dnssec = false
  tags = {
    Team = "network"
  }
}

run "plan_dnssec_disabled" {
  command = plan

  assert {
    condition     = aws_route53_zone.workload_zone.name == var.domain_name
    error_message = "Hosted zone name should match domain_name."
  }

  assert {
    condition     = length(aws_kms_key.dnssec_key) == 0
    error_message = "KMS key should not be created when DNSSEC is disabled."
  }

  assert {
    condition     = output.dnssec_ds_record == null
    error_message = "DNSSEC DS record output should be null when DNSSEC is disabled."
  }

  assert {
    condition     = aws_route53_zone.workload_zone.tags["Environment"] == var.environment
    error_message = "Hosted zone should include environment tag from module input."
  }

  assert {
    condition     = aws_route53_zone.workload_zone.tags["Team"] == "network"
    error_message = "Hosted zone should preserve caller-provided Team tag."
  }
}

run "plan_dnssec_enabled" {
  command = plan

  variables {
    enable_dnssec = true
  }

  assert {
    condition     = length(aws_kms_key.dnssec_key) == 1
    error_message = "KMS key should be created when DNSSEC is enabled."
  }

  assert {
    condition     = length(aws_route53_key_signing_key.ksk) == 1
    error_message = "Key signing key should be created when DNSSEC is enabled."
  }

  assert {
    condition     = length(aws_route53_hosted_zone_dnssec.dnssec) == 1
    error_message = "Route53 DNSSEC resource should be created when DNSSEC is enabled."
  }

  assert {
    condition     = aws_route53_key_signing_key.ksk[0].name == "dnssec-ksk"
    error_message = "Key signing key should use the expected stable name."
  }
}

run "plan_dnssec_disabled_with_no_extra_tags" {
  command = plan

  variables {
    tags = {}
  }

  assert {
    condition     = aws_route53_zone.workload_zone.tags["Environment"] == var.environment
    error_message = "Environment tag should always be present even when extra tags are omitted."
  }

  assert {
    condition     = length(aws_kms_key.dnssec_key) == 0
    error_message = "KMS key should remain disabled when DNSSEC is false."
  }
}

run "plan_additional_domains_without_dnssec" {
  command = plan

  variables {
    enable_dnssec = false
    additional_domain_names = [
      "extra1.example.gov.uk",
      "extra2.example.gov.uk",
    ]
  }

  # One additional workload zone per additional domain, named after the domain.
  assert {
    condition     = aws_route53_zone.additional_workload_zones["extra1.example.gov.uk"].name == "extra1.example.gov.uk"
    error_message = "Additional workload zone should be named after the additional domain."
  }

  assert {
    condition     = length(aws_route53_zone.additional_workload_zones) == 2
    error_message = "One additional workload zone should be created per additional domain."
  }

  # Additional zones inherit environment + user tags like the primary zone.
  assert {
    condition     = aws_route53_zone.additional_workload_zones["extra2.example.gov.uk"].tags["Environment"] == var.environment
    error_message = "Additional workload zone should carry the environment tag."
  }

  assert {
    condition     = aws_route53_zone.additional_workload_zones["extra2.example.gov.uk"].tags["Team"] == "network"
    error_message = "Additional workload zone should preserve caller-provided tags."
  }

  # No DNSSEC resources for additional domains when DNSSEC is disabled.
  assert {
    condition     = length(aws_kms_key.additional_dnssec_keys) == 0
    error_message = "No additional DNSSEC KMS keys should exist when DNSSEC is disabled."
  }

  assert {
    condition     = length(aws_route53_key_signing_key.additional_ksks) == 0
    error_message = "No additional key signing keys should exist when DNSSEC is disabled."
  }

  assert {
    condition     = length(aws_route53_hosted_zone_dnssec.additional_dnssec) == 0
    error_message = "No additional hosted-zone DNSSEC resources should exist when DNSSEC is disabled."
  }

  assert {
    condition     = output.additional_dnssec_ds_record == null
    error_message = "additional_dnssec_ds_record output should be null when DNSSEC is disabled."
  }
}

run "plan_additional_domains_with_dnssec" {
  command = plan

  variables {
    enable_dnssec = true
    additional_domain_names = [
      "extra1.example.gov.uk",
      "extra2.example.gov.uk",
    ]
  }

  # One DNSSEC resource set per additional domain when DNSSEC is enabled.
  assert {
    condition     = length(aws_kms_key.additional_dnssec_keys) == 2
    error_message = "One additional DNSSEC KMS key should be created per additional domain."
  }

  assert {
    condition     = length(aws_route53_key_signing_key.additional_ksks) == 2
    error_message = "One additional key signing key should be created per additional domain."
  }

  assert {
    condition     = length(aws_route53_hosted_zone_dnssec.additional_dnssec) == 2
    error_message = "One additional hosted-zone DNSSEC resource should be created per additional domain."
  }

  assert {
    condition     = aws_route53_key_signing_key.additional_ksks["extra1.example.gov.uk"].name == "dnssec-ksk"
    error_message = "Additional key signing key should use the expected stable name."
  }
}

run "plan_no_additional_domains_by_default" {
  command = plan

  assert {
    condition     = length(aws_route53_zone.additional_workload_zones) == 0
    error_message = "No additional workload zones should be created when the list is empty (default)."
  }

  assert {
    condition     = output.additional_zone_ids == {}
    error_message = "additional_zone_ids should be an empty map when no additional domains are set."
  }
}
