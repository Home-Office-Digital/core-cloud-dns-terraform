mock_provider "aws" {}
mock_provider "random" {}

variables {
  vpc_name           = "shared-services-vpc"
  internal_domain_name = "np.internal.example.gov.uk"
  route53_profile_id = "r53p-1234567890abcdef"
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
