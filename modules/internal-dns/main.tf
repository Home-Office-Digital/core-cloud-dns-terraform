#################################################################################################################
#################################################################################################################
# Creates a private hosted zone (single domain + VPC name - uses data to obtain VPC ID)
# Creates a public hosted zone (same domain)
# Attach VPC to R53 Profile Id (VPC from data, profile id from GitHub env var)
# Attach PHZ to R53 Profile Id
# Create a wildcard cert matching the public zone and validate it
#################################################################################################################
#################################################################################################################

############################
# Data: VPC lookup by Name
############################
data "aws_vpcs" "selected" {
  filter {
    name   = "tag:Name"
    values = [var.vpc_name]
  }
}

locals {
  vpc_id = data.aws_vpcs.selected.ids[0]
  domain = var.internal_domain_name
}

############################
# Route 53 Hosted Zones
############################

# Private Hosted Zone (PHZ) - created and associated to the selected VPC
resource "aws_route53_zone" "private" {
  name = local.domain

  vpc {
    vpc_id = local.vpc_id
  }

  comment = "Private hosted zone for ${local.domain} (managed by Terraform)"
  tags    = var.tags
}

# Public Hosted Zone (for ACM DNS validation records)
resource "aws_route53_zone" "public" {
  name    = local.domain
  comment = "Public hosted zone for ${local.domain} (ACM validation records"
  tags    = var.tags
}

############################
# Route 53 Profiles
############################

# Attach VPC to Route 53 Profile
resource "aws_route53profiles_association" "vpc_to_profile" {
  name        = "${var.vpc_name}-association"
  profile_id  = var.route53_profile_id
  resource_id = local.vpc_id
  tags        = var.tags
}

resource "random_id" "phz_assoc" {
  byte_length = 4
}


# Attach PHZ to Route 53 Profile
resource "aws_route53profiles_resource_association" "phz_to_profile" {
  name         = "phz-${random_id.phz_assoc.hex}"
  profile_id   = var.route53_profile_id
  resource_arn = aws_route53_zone.private.arn
}

############################
# Route 53 Additional Hosted Zones
############################

# Private Hosted Zone (PHZ) - created and associated to the selected VPC
resource "aws_route53_zone" "additional_private" {
  for_each = try(toset(var.additional_internal_domain_names), {})
  name     = each.key

  vpc {
    vpc_id = local.vpc_id
  }

  comment = "Private hosted zone for ${each.key} (managed by Terraform)"
  tags    = var.tags
}

# Public Hosted Zone (for ACM DNS validation records)
resource "aws_route53_zone" "additional_public" {
  for_each = try(toset(var.additional_internal_domain_names), {})
  name     = each.key
  comment  = "Public hosted zone for ${each.key} (ACM validation records"
  tags     = var.tags
}

############################
# Route 53 Profiles - additional domains
############################
resource "random_id" "additional_phz_assoc" {
  for_each    = try(toset(var.additional_internal_domain_names), {})
  byte_length = 4
}

# Attach PHZ to Route 53 Profile
resource "aws_route53profiles_resource_association" "additional_phz_to_profile" {
  for_each     = try(toset(var.additional_internal_domain_names), {})
  name         = "phz-${random_id.additional_phz_assoc[each.key].hex}"
  profile_id   = var.route53_profile_id
  resource_arn = aws_route53_zone.additional_private[each.key].arn
}
