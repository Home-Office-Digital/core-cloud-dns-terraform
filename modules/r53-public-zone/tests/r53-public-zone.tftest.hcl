mock_provider "aws" {}

variables {
  domain_name  = "service.example.gov.uk"
  environment  = "nonprod"
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
