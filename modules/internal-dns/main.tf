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
  comment = "Public hosted zone for ${local.domain} (ACM validation records)"
  tags    = var.tags
}

data "aws_caller_identity" "current" {}

resource "aws_kms_key" "dnssec_key" {
  count               = var.enable_dnssec ? 1 : 0
  description         = "KMS key for DNSSEC signing for ${local.domain} (ACM validation records)"
  enable_key_rotation = true

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "Enable IAM User Permissions"
        Effect = "Allow"
        Principal = {
          AWS = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:root"
        }
        Action   = "kms:*"
        Resource = "*"
      },
      {
        Sid    = "Allow Route53 DNSSEC"
        Effect = "Allow"
        Principal = {
          Service = "dnssec-route53.amazonaws.com"
        }
        Action = [
          "kms:DescribeKey",
          "kms:GetPublicKey",
          "kms:Sign"
        ]
        Resource = "*"
      }
    ]
  })
}

resource "aws_route53_key_signing_key" "ksk" {
  count                      = var.enable_dnssec ? 1 : 0
  hosted_zone_id             = aws_route53_zone.public.zone_id
  name                       = "dnssec-ksk"
  key_management_service_arn = aws_kms_key.dnssec_key[0].arn
}

resource "aws_route53_hosted_zone_dnssec" "dnssec" {
  count          = var.enable_dnssec ? 1 : 0
  hosted_zone_id = aws_route53_zone.public.zone_id
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

#Query Logging Option
# KMS key used to encrypt the Route 53 query-log CloudWatch log groups.
# The key policy must allow the CloudWatch Logs service principal to use the
# key, otherwise log group creation fails.
data "aws_region" "current" {}

resource "aws_kms_key" "r53_query_log_key" {
  count                   = var.enable_r53_query_logging ? 1 : 0
  description             = "KMS key for Route53 query log encryption for ${local.domain}"
  enable_key_rotation     = true
  deletion_window_in_days = 7

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "Enable IAM User Permissions"
        Effect = "Allow"
        Principal = {
          AWS = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:root"
        }
        Action   = "kms:*"
        Resource = "*"
      },
      {
        Sid    = "Allow CloudWatch Logs"
        Effect = "Allow"
        Principal = {
          Service = "logs.${data.aws_region.current.name}.amazonaws.com"
        }
        Action = [
          "kms:Encrypt",
          "kms:Decrypt",
          "kms:ReEncrypt*",
          "kms:GenerateDataKey*",
          "kms:DescribeKey"
        ]
        Resource = "*"
        Condition = {
          ArnLike = {
            "kms:EncryptionContext:aws:logs:arn" = "arn:aws:logs:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:log-group:/aws/route53/*"
          }
        }
      }
    ]
  })
}

resource "aws_cloudwatch_log_group" "r53_log_group" {
  count             = var.enable_r53_query_logging ? 1 : 0
  name              = "/aws/route53/${local.domain}"
  retention_in_days = var.enable_r53_query_logging_length
  kms_key_id        = aws_kms_key.r53_query_log_key[0].arn
}

resource "aws_cloudwatch_log_group" "r53_log_group_phz" {
  count             = var.enable_r53_query_logging ? 1 : 0
  name              = "/aws/route53/phz_${local.domain}"
  retention_in_days = var.enable_r53_query_logging_length
  kms_key_id        = aws_kms_key.r53_query_log_key[0].arn
}

resource "aws_route53_query_log" "r53_query_log" {
  count                    = var.enable_r53_query_logging ? 1 : 0
  cloudwatch_log_group_arn = aws_cloudwatch_log_group.r53_log_group[0].arn
  zone_id                  = aws_route53_zone.public.zone_id
}

resource "aws_route53_query_log" "r53_query_log_phz" {
  count                    = var.enable_r53_query_logging ? 1 : 0
  cloudwatch_log_group_arn = aws_cloudwatch_log_group.r53_log_group_phz[0].arn
  zone_id                  = aws_route53_zone.private.zone_id
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

#### Additional Domain Name DNSSEC
resource "aws_kms_key" "additional_dnssec_keys" {
  for_each            = var.enable_dnssec ? toset(var.additional_internal_domain_names) : toset([])
  description         = "KMS key for DNSSEC signing for ${each.key}"
  enable_key_rotation = true

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "Enable IAM User Permissions"
        Effect = "Allow"
        Principal = {
          AWS = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:root"
        }
        Action   = "kms:*"
        Resource = "*"
      },
      {
        Sid    = "Allow Route53 DNSSEC"
        Effect = "Allow"
        Principal = {
          Service = "dnssec-route53.amazonaws.com"
        }
        Action = [
          "kms:DescribeKey",
          "kms:GetPublicKey",
          "kms:Sign"
        ]
        Resource = "*"
      }
    ]
  })
}

resource "aws_route53_key_signing_key" "additional_ksks" {
  for_each                   = var.enable_dnssec ? try(toset(var.additional_internal_domain_names), toset([])) : toset([])
  hosted_zone_id             = aws_route53_zone.additional_public[each.key].zone_id
  name                       = "dnssec-ksk"
  key_management_service_arn = aws_kms_key.additional_dnssec_keys[each.key].arn
}

resource "aws_route53_hosted_zone_dnssec" "additional_dnssec" {
  for_each       = var.enable_dnssec ? try(toset(var.additional_internal_domain_names), toset([])) : toset([])
  hosted_zone_id = aws_route53_zone.additional_public[each.key].zone_id
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

#Query Logging Option for Additional Domains
resource "aws_cloudwatch_log_group" "additional_r53_log_groups" {
  for_each          = var.enable_r53_query_logging ? try(toset(var.additional_internal_domain_names), toset([])) : toset([])
  name              = "/aws/route53/${each.key}"
  retention_in_days = var.enable_r53_query_logging_length
  kms_key_id        = aws_kms_key.r53_query_log_key[0].arn
}

resource "aws_cloudwatch_log_group" "additional_r53_log_groups_phz" {
  for_each          = var.enable_r53_query_logging ? try(toset(var.additional_internal_domain_names), toset([])) : toset([])
  name              = "/aws/route53/phz_${each.key}"
  retention_in_days = var.enable_r53_query_logging_length
  kms_key_id        = aws_kms_key.r53_query_log_key[0].arn
}

resource "aws_route53_query_log" "additional_r53_query_logs" {
  for_each                 = var.enable_r53_query_logging ? try(toset(var.additional_internal_domain_names), toset([])) : toset([])
  cloudwatch_log_group_arn = aws_cloudwatch_log_group.additional_r53_log_groups[each.key].arn
  zone_id                  = aws_route53_zone.additional_public[each.key].zone_id
}

resource "aws_route53_query_log" "additional_r53_query_logs_phz" {
  for_each                 = var.enable_r53_query_logging ? try(toset(var.additional_internal_domain_names), toset([])) : toset([])
  cloudwatch_log_group_arn = aws_cloudwatch_log_group.additional_r53_log_groups_phz[each.key].arn
  zone_id                  = aws_route53_zone.additional_private[each.key].zone_id
}
