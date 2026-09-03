mock_provider "aws" {}
mock_provider "random" {}

variables {
  vpc_name             = "shared-services-vpc"
  internal_domain_name = "np.internal.example.gov.uk"
  route53_profile_id   = "r53p-1234567890abcdef"
  tags = {
    Owner = "platform"
  }
}

run "plan_internal_dns" {
  command = plan

  override_data {
    target = data.aws_vpcs.selected
    values = {
      ids = ["vpc-1234567890abcdef0"]
    }
  }

  assert {
    condition     = aws_route53_zone.private.name == var.internal_domain_name
    error_message = "Private hosted zone should use the module domain name."
  }

  assert {
    condition     = aws_route53_zone.public.name == var.internal_domain_name
    error_message = "Public hosted zone should use the module domain name."
  }

  assert {
    condition     = aws_route53profiles_association.vpc_to_profile.profile_id == var.route53_profile_id
    error_message = "VPC to profile association should use the provided profile ID."
  }

  assert {
    condition     = aws_route53profiles_association.vpc_to_profile.name == "${var.vpc_name}-association"
    error_message = "VPC to profile association name should include the VPC name."
  }

  assert {
    condition     = aws_route53profiles_resource_association.phz_to_profile.profile_id == var.route53_profile_id
    error_message = "PHZ association should use the provided profile ID."
  }

  assert {
    condition     = aws_route53profiles_association.vpc_to_profile.resource_id == "vpc-1234567890abcdef0"
    error_message = "VPC association should use the resolved VPC ID from data lookup."
  }

  assert {
    condition     = startswith(aws_route53profiles_resource_association.phz_to_profile.name, "phz-")
    error_message = "PHZ profile association name should include the phz- prefix."
  }

  assert {
    condition     = aws_route53_zone.private.tags["Owner"] == "platform"
    error_message = "Private hosted zone should inherit user tags."
  }

  assert {
    condition     = aws_route53_zone.public.tags["Owner"] == "platform"
    error_message = "Public hosted zone should inherit user tags."
  }
}

run "plan_internal_dns_with_minimal_tags" {
  command = plan

  variables {
    tags = {}
  }

  override_data {
    target = data.aws_vpcs.selected
    values = {
      ids = ["vpc-abcdefabcdefabcd0"]
    }
  }

  assert {
    condition     = contains([for v in aws_route53_zone.private.vpc : v.vpc_id], "vpc-abcdefabcdefabcd0")
    error_message = "Private zone should attach to the resolved VPC ID in minimal-tag scenario."
  }

  assert {
    condition     = aws_route53profiles_association.vpc_to_profile.resource_id == "vpc-abcdefabcdefabcd0"
    error_message = "Profile association should target the resolved VPC ID in minimal-tag scenario."
  }
}

run "plan_internal_dns_with_additional_domains" {
  command = plan

  variables {
    additional_internal_domain_names = [
      "extra1.np.internal.example.gov.uk",
      "extra2.np.internal.example.gov.uk",
    ]
  }

  override_data {
    target = data.aws_vpcs.selected
    values = {
      ids = ["vpc-1234567890abcdef0"]
    }
  }

  # A private + public hosted zone is created for each additional domain.
  assert {
    condition     = aws_route53_zone.additional_private["extra1.np.internal.example.gov.uk"].name == "extra1.np.internal.example.gov.uk"
    error_message = "Additional private zone should be named after the additional domain."
  }

  assert {
    condition     = aws_route53_zone.additional_public["extra1.np.internal.example.gov.uk"].name == "extra1.np.internal.example.gov.uk"
    error_message = "Additional public zone should be named after the additional domain."
  }

  assert {
    condition     = length(aws_route53_zone.additional_private) == 2
    error_message = "One additional private zone should be created per additional domain."
  }

  assert {
    condition     = length(aws_route53_zone.additional_public) == 2
    error_message = "One additional public zone should be created per additional domain."
  }

  # Additional private zones attach to the resolved VPC, like the primary zone.
  assert {
    condition     = contains([for v in aws_route53_zone.additional_private["extra2.np.internal.example.gov.uk"].vpc : v.vpc_id], "vpc-1234567890abcdef0")
    error_message = "Additional private zone should attach to the resolved VPC ID."
  }

  # A profile association (and its random_id) is created per additional domain.
  assert {
    condition     = length(aws_route53profiles_resource_association.additional_phz_to_profile) == 2
    error_message = "One profile resource association should be created per additional domain."
  }

  assert {
    condition     = aws_route53profiles_resource_association.additional_phz_to_profile["extra1.np.internal.example.gov.uk"].profile_id == var.route53_profile_id
    error_message = "Additional PHZ association should use the provided profile ID."
  }

  assert {
    condition     = startswith(aws_route53profiles_resource_association.additional_phz_to_profile["extra1.np.internal.example.gov.uk"].name, "phz-")
    error_message = "Additional PHZ association name should carry the phz- prefix."
  }

  # Additional zones inherit user tags.
  assert {
    condition     = aws_route53_zone.additional_public["extra1.np.internal.example.gov.uk"].tags["Owner"] == "platform"
    error_message = "Additional public zone should inherit user tags."
  }
}

run "plan_internal_dns_without_additional_domains_creates_none" {
  command = plan

  override_data {
    target = data.aws_vpcs.selected
    values = {
      ids = ["vpc-1234567890abcdef0"]
    }
  }

  assert {
    condition     = length(aws_route53_zone.additional_private) == 0
    error_message = "No additional private zones should be created when the list is empty (default)."
  }

  assert {
    condition     = length(aws_route53_zone.additional_public) == 0
    error_message = "No additional public zones should be created when the list is empty (default)."
  }

  assert {
    condition     = length(aws_route53profiles_resource_association.additional_phz_to_profile) == 0
    error_message = "No additional profile associations should be created when the list is empty (default)."
  }
}

run "plan_internal_dns_dnssec_disabled_by_default" {
  command = plan

  override_data {
    target = data.aws_vpcs.selected
    values = {
      ids = ["vpc-1234567890abcdef0"]
    }
  }

  # DNSSEC defaults to off: none of the primary DNSSEC resources are created.
  assert {
    condition     = length(aws_kms_key.dnssec_key) == 0
    error_message = "No DNSSEC KMS key should be created when enable_dnssec is false (default)."
  }

  assert {
    condition     = length(aws_route53_key_signing_key.ksk) == 0
    error_message = "No key signing key should be created when DNSSEC is disabled."
  }

  assert {
    condition     = length(aws_route53_hosted_zone_dnssec.dnssec) == 0
    error_message = "No hosted-zone DNSSEC resource should be created when DNSSEC is disabled."
  }
}

run "plan_internal_dns_dnssec_enabled" {
  command = plan

  variables {
    enable_dnssec = true
  }

  override_data {
    target = data.aws_vpcs.selected
    values = {
      ids = ["vpc-1234567890abcdef0"]
    }
  }

  # Primary domain DNSSEC resources are created and sign the PUBLIC zone.
  assert {
    condition     = length(aws_kms_key.dnssec_key) == 1
    error_message = "A DNSSEC KMS key should be created when enable_dnssec is true."
  }

  assert {
    condition     = length(aws_route53_key_signing_key.ksk) == 1
    error_message = "A key signing key should be created when DNSSEC is enabled."
  }

  assert {
    condition     = aws_route53_key_signing_key.ksk[0].name == "dnssec-ksk"
    error_message = "Key signing key should use the expected stable name."
  }

  assert {
    condition     = length(aws_route53_hosted_zone_dnssec.dnssec) == 1
    error_message = "A hosted-zone DNSSEC resource should be created when DNSSEC is enabled."
  }
}

run "plan_internal_dns_additional_domains_dnssec_enabled" {
  command = plan

  variables {
    enable_dnssec = true
    additional_internal_domain_names = [
      "extra1.np.internal.example.gov.uk",
      "extra2.np.internal.example.gov.uk",
    ]
  }

  override_data {
    target = data.aws_vpcs.selected
    values = {
      ids = ["vpc-1234567890abcdef0"]
    }
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
}

run "plan_internal_dns_additional_domains_dnssec_disabled" {
  command = plan

  variables {
    enable_dnssec = false
    additional_internal_domain_names = [
      "extra1.np.internal.example.gov.uk",
    ]
  }

  override_data {
    target = data.aws_vpcs.selected
    values = {
      ids = ["vpc-1234567890abcdef0"]
    }
  }

  # Additional zones still created, but no DNSSEC resources when disabled.
  assert {
    condition     = length(aws_route53_zone.additional_public) == 1
    error_message = "Additional public zone should still be created when DNSSEC is disabled."
  }

  assert {
    condition     = length(aws_kms_key.additional_dnssec_keys) == 0
    error_message = "No additional DNSSEC KMS keys should exist when DNSSEC is disabled."
  }

  assert {
    condition     = length(aws_route53_hosted_zone_dnssec.additional_dnssec) == 0
    error_message = "No additional hosted-zone DNSSEC resources should exist when DNSSEC is disabled."
  }
}
