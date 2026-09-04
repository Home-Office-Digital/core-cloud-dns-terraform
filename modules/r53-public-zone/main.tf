resource "aws_route53_zone" "workload_zone" {
  name = var.domain_name

  tags = merge(
    {
      Environment = var.environment
    },
    var.tags
  )
}

data "aws_caller_identity" "current" {}

resource "aws_kms_key" "dnssec_key" {
  count               = var.enable_dnssec ? 1 : 0
  description         = "KMS key for DNSSEC signing for ${var.domain_name}"
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
  hosted_zone_id             = aws_route53_zone.workload_zone.zone_id
  name                       = "dnssec-ksk"
  key_management_service_arn = aws_kms_key.dnssec_key[0].arn
}

resource "aws_route53_hosted_zone_dnssec" "dnssec" {
  count          = var.enable_dnssec ? 1 : 0
  hosted_zone_id = aws_route53_zone.workload_zone.zone_id
}

#Query Logging Option
# KMS key used to encrypt the Route 53 query-log CloudWatch log groups.
# The key policy must allow the CloudWatch Logs service principal to use the
# key, otherwise log group creation fails.
data "aws_region" "current" {}

resource "aws_kms_key" "r53_query_log_key" {
  count                   = var.enable_r53_query_logging ? 1 : 0
  description             = "KMS key for Route53 query log encryption for ${var.domain_name}"
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
  name              = "/aws/route53/${var.domain_name}"
  
  retention_in_days = 365
  kms_key_id        = aws_kms_key.r53_query_log_key[0].arn
}

resource "aws_route53_query_log" "r53_query_log" {
  count                    = var.enable_r53_query_logging ? 1 : 0
  cloudwatch_log_group_arn = aws_cloudwatch_log_group.r53_log_group[0].arn
  zone_id                  = aws_route53_zone.workload_zone.zone_id
}

#### Additional Domain Names
resource "aws_route53_zone" "additional_workload_zones" {
  for_each = try(toset(var.additional_domain_names), {})
  name     = each.key

  tags = merge(
    {
      Environment = var.environment
    },
    var.tags
  )
}

#### Additional Domain Name DNSSEC
resource "aws_kms_key" "additional_dnssec_keys" {
  for_each            = var.enable_dnssec ? toset(var.additional_domain_names) : toset([])
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
  for_each                   = var.enable_dnssec ? try(toset(var.additional_domain_names), toset([])) : toset([])
  hosted_zone_id             = aws_route53_zone.additional_workload_zones[each.key].zone_id
  name                       = "dnssec-ksk"
  key_management_service_arn = aws_kms_key.additional_dnssec_keys[each.key].arn
}

resource "aws_route53_hosted_zone_dnssec" "additional_dnssec" {
  for_each       = var.enable_dnssec ? try(toset(var.additional_domain_names), toset([])) : toset([])
  hosted_zone_id = aws_route53_zone.additional_workload_zones[each.key].zone_id
}

#Query Logging Option for Additional Domains
resource "aws_cloudwatch_log_group" "additional_r53_log_groups" {
  for_each          = var.enable_r53_query_logging ? try(toset(var.additional_domain_names), toset([])) : toset([])
  name              = "/aws/route53/${each.key}"
  
  retention_in_days = 365
  kms_key_id        = aws_kms_key.r53_query_log_key[0].arn
}

resource "aws_route53_query_log" "additional_r53_query_logs" {
  for_each                 = var.enable_r53_query_logging ? try(toset(var.additional_domain_names), toset([])) : toset([])
  cloudwatch_log_group_arn = aws_cloudwatch_log_group.additional_r53_log_groups[each.key].arn
  zone_id                  = aws_route53_zone.additional_workload_zones[each.key].zone_id
}
