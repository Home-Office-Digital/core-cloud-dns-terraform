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
