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

run "plan_query_logging_disabled_by_default" {
  command = plan

  # Query logging defaults to off.
  assert {
    condition     = length(aws_cloudwatch_log_group.r53_log_group) == 0
    error_message = "No log group should be created when query logging is disabled (default)."
  }

  assert {
    condition     = length(aws_route53_query_log.r53_query_log) == 0
    error_message = "No query log should be created when query logging is disabled (default)."
  }
}

run "plan_query_logging_enabled" {
  command = plan

  variables {
    enable_r53_query_logging = true
    r53_query_logging_length = 90
  }

  assert {
    condition     = length(aws_cloudwatch_log_group.r53_log_group) == 1
    error_message = "A log group should be created when query logging is enabled."
  }

  assert {
    condition     = length(aws_route53_query_log.r53_query_log) == 1
    error_message = "A query log should be created when query logging is enabled."
  }

  assert {
    condition     = aws_cloudwatch_log_group.r53_log_group[0].retention_in_days == 90
    error_message = "Log group retention should use the configured r53_query_logging_length."
  }
}

run "plan_additional_domains_query_logging_enabled" {
  command = plan

  variables {
    enable_r53_query_logging = true
    additional_domain_names = [
      "extra1.example.gov.uk",
      "extra2.example.gov.uk",
    ]
  }

  # One log group + query log per additional domain when enabled.
  assert {
    condition     = length(aws_cloudwatch_log_group.additional_r53_log_groups) == 2
    error_message = "One additional log group should be created per additional domain."
  }

  assert {
    condition     = length(aws_route53_query_log.additional_r53_query_logs) == 2
    error_message = "One additional query log should be created per additional domain."
  }
}

run "plan_additional_domains_query_logging_disabled" {
  command = plan

  variables {
    enable_r53_query_logging = false
    additional_domain_names = [
      "extra1.example.gov.uk",
    ]
  }

  # Additional zone still created, but no query-logging resources when disabled.
  assert {
    condition     = length(aws_route53_zone.additional_workload_zones) == 1
    error_message = "Additional workload zone should still be created when query logging is disabled."
  }

  assert {
    condition     = length(aws_cloudwatch_log_group.additional_r53_log_groups) == 0
    error_message = "No additional log groups should exist when query logging is disabled."
  }

  assert {
    condition     = length(aws_route53_query_log.additional_r53_query_logs) == 0
    error_message = "No additional query logs should exist when query logging is disabled."
  }
}

run "plan_query_logging_kms_key_created_when_enabled" {
  command = plan

  variables {
    enable_r53_query_logging = true
    additional_domain_names = [
      "extra1.example.gov.uk",
    ]
  }

  # A KMS key is created for query-log encryption when logging is enabled.
  assert {
    condition     = length(aws_kms_key.r53_query_log_key) == 1
    error_message = "A KMS key should be created for query-log encryption when logging is enabled."
  }

  assert {
    condition     = aws_kms_key.r53_query_log_key[0].enable_key_rotation == true
    error_message = "The query-log KMS key should have key rotation enabled."
  }

  # Note: the log groups reference aws_kms_key.r53_query_log_key[0].arn for
  # kms_key_id (see main.tf). Under a mocked plan the concrete ARN is unknown,
  # so the cross-reference cannot be asserted here; presence of the key plus a
  # successful plan confirm the wiring is in place.
}

run "plan_query_logging_kms_key_absent_when_disabled" {
  command = plan

  variables {
    enable_r53_query_logging = false
  }

  assert {
    condition     = length(aws_kms_key.r53_query_log_key) == 0
    error_message = "No query-log KMS key should be created when query logging is disabled."
  }
}
