###############################################################################
# DNS observability — Resolver query logging + CloudWatch metric alarms
#
# Purpose: make DNS Firewall Advanced ALERT mode actionable. Query logging
# records every query and the DNS Firewall action taken (so ALERT matches are
# visible for tuning before any BLOCK); CloudWatch alarms surface spikes in
# Advanced-rule matches.
#
# DNS Firewall itself already publishes metrics to the AWS/Route53Resolver
# namespace automatically — no config needed for the metrics to exist. This
# file adds the log sink and alarms on top of them.
###############################################################################

########################################
# Resolver query logging -> CloudWatch (KMS-encrypted)
########################################

data "aws_caller_identity" "current" {}
data "aws_region" "current" {}

# KMS key to encrypt the Resolver query log group (CKV_AWS_158). Mirrors the
# r53-public-zone query-log key convention: CloudWatch Logs service principal
# allowed, scoped via the encryption-context condition to this log-group path.
resource "aws_kms_key" "resolver_query_log_key" {
  count = var.enable_resolver_query_logging ? 1 : 0

  description             = "KMS key for Route 53 Resolver query log encryption (${var.vpc_name})"
  enable_key_rotation     = true
  deletion_window_in_days = 7

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid       = "Enable IAM User Permissions"
        Effect    = "Allow"
        Principal = { AWS = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:root" }
        Action    = "kms:*"
        Resource  = "*"
      },
      {
        Sid       = "Allow CloudWatch Logs"
        Effect    = "Allow"
        Principal = { Service = "logs.${data.aws_region.current.region}.amazonaws.com" }
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
            "kms:EncryptionContext:aws:logs:arn" = "arn:aws:logs:${data.aws_region.current.region}:${data.aws_caller_identity.current.account_id}:log-group:/aws/route53resolver/*"
          }
        }
      }
    ]
  })

  tags = merge(
    var.tags,
    {
      Environment = "prod"
      Account     = "Network"
      Component   = "r53-query-logging"
    }
  )
}

resource "aws_cloudwatch_log_group" "resolver_query_log" {
  count = var.enable_resolver_query_logging ? 1 : 0

  name              = "/aws/route53resolver/${var.vpc_name}-query-logs"
  retention_in_days = var.resolver_query_log_retention_days
  kms_key_id        = aws_kms_key.resolver_query_log_key[0].arn

  tags = merge(
    var.tags,
    {
      Environment = "prod"
      Account     = "Network"
      Component   = "r53-query-logging"
    }
  )
}

resource "aws_route53_resolver_query_log_config" "this" {
  count = var.enable_resolver_query_logging ? 1 : 0

  name            = "${var.vpc_name}-resolver-query-log"
  destination_arn = aws_cloudwatch_log_group.resolver_query_log[0].arn

  tags = merge(
    var.tags,
    {
      Environment = "prod"
      Account     = "Network"
      Component   = "r53-query-logging"
    }
  )
}

resource "aws_route53_resolver_query_log_config_association" "this" {
  count = var.enable_resolver_query_logging ? 1 : 0

  resolver_query_log_config_id = aws_route53_resolver_query_log_config.this[0].id
  resource_id                  = var.vpc_id
}

########################################
# CloudWatch alarm on DNS Firewall rule-group query volume
#
# DNS Firewall publishes match counts to AWS/Route53Resolver at the RULE GROUP
# granularity (FirewallRuleGroupQueryVolume, dimension FirewallRuleGroupId).
# There is no per-rule/per-detector metric, so this is a single alarm on the
# whole group's match volume. Per-detector visibility comes from the query logs
# (which record the acting rule) and the dashboard's Logs Insights panel.
########################################

resource "aws_cloudwatch_metric_alarm" "firewall_match_volume" {
  count = var.enable_dns_firewall_alarms ? 1 : 0

  alarm_name          = "cc-dns-firewall-${var.rule_group_name}-match-volume"
  alarm_description   = "DNS Firewall rule group ${var.rule_group_name} matched queries above threshold. Includes managed/custom BLOCKs and Advanced (tunnelling/DGA) ALERTs — inspect Resolver query logs to attribute."
  namespace           = "AWS/Route53Resolver"
  metric_name         = "FirewallRuleGroupQueryVolume"
  statistic           = "Sum"
  comparison_operator = "GreaterThanThreshold"
  threshold           = var.dns_firewall_alarm_threshold
  period              = 300
  evaluation_periods  = 1
  treat_missing_data  = "notBreaching"

  dimensions = {
    FirewallRuleGroupId = aws_route53_resolver_firewall_rule_group.rule_group.id
  }

  alarm_actions = var.dns_firewall_alarm_sns_topic_arn != "" ? [var.dns_firewall_alarm_sns_topic_arn] : []
  ok_actions    = var.dns_firewall_alarm_sns_topic_arn != "" ? [var.dns_firewall_alarm_sns_topic_arn] : []

  tags = merge(
    var.tags,
    {
      Environment = "prod"
      Account     = "Network"
      Component   = "r53-firewall"
    }
  )
}

########################################
# CloudWatch dashboard — central DNS view for the network hub
#
# This account owns the org-shared R53 Profile and all inbound/outbound
# resolver endpoints, so this dashboard is effectively an estate-wide DNS view:
# firewall match volume, per-endpoint query volume (incl. PDNS forwarding),
# endpoint health, and top DNS Firewall-actioned domains from the query logs.
########################################

resource "aws_cloudwatch_dashboard" "dns" {
  count = var.enable_dns_dashboard ? 1 : 0

  dashboard_name = "${var.vpc_name}-dns-dashboard"

  dashboard_body = jsonencode({
    widgets = [
      {
        type = "metric", x = 0, y = 0, width = 12, height = 6
        properties = {
          title  = "DNS Firewall — rule group match volume"
          region = var.aws_region
          view   = "timeSeries"
          stat   = "Sum"
          period = 300
          metrics = [
            ["AWS/Route53Resolver", "FirewallRuleGroupQueryVolume", "FirewallRuleGroupId", aws_route53_resolver_firewall_rule_group.rule_group.id, { label = var.rule_group_name }]
          ]
        }
      },
      {
        type = "metric", x = 12, y = 0, width = 12, height = 6
        properties = {
          title  = "Outbound query volume — PDNS / POISE forwarding"
          region = var.aws_region
          view   = "timeSeries"
          stat   = "Sum"
          period = 300
          metrics = [
            ["AWS/Route53Resolver", "OutboundQueryVolume", "EndpointId", aws_route53_resolver_endpoint.cc_ncsc_outbound_endpoint.id, { label = "NCSC PDNS outbound" }],
            ["AWS/Route53Resolver", "OutboundQueryVolume", "EndpointId", aws_route53_resolver_endpoint.cc_poise_outbound_endpoint.id, { label = "POISE outbound" }]
          ]
        }
      },
      {
        type = "metric", x = 0, y = 6, width = 12, height = 6
        properties = {
          title  = "Inbound query volume"
          region = var.aws_region
          view   = "timeSeries"
          stat   = "Sum"
          period = 300
          metrics = [
            ["AWS/Route53Resolver", "InboundQueryVolume", "EndpointId", aws_route53_resolver_endpoint.cc_inbound_endpoint.id, { label = "Inbound endpoint" }]
          ]
        }
      },
      {
        type = "metric", x = 12, y = 6, width = 12, height = 6
        properties = {
          title  = "Resolver endpoint health (healthy ENIs)"
          region = var.aws_region
          view   = "timeSeries"
          stat   = "Minimum"
          period = 300
          metrics = [
            ["AWS/Route53Resolver", "EndpointHealthyENICount", "EndpointId", aws_route53_resolver_endpoint.cc_inbound_endpoint.id, { label = "Inbound" }],
            ["AWS/Route53Resolver", "EndpointHealthyENICount", "EndpointId", aws_route53_resolver_endpoint.cc_ncsc_outbound_endpoint.id, { label = "NCSC outbound" }],
            ["AWS/Route53Resolver", "EndpointHealthyENICount", "EndpointId", aws_route53_resolver_endpoint.cc_poise_outbound_endpoint.id, { label = "POISE outbound" }]
          ]
        }
      },
      {
        type = "log", x = 0, y = 12, width = 24, height = 6
        properties = {
          title  = "Top DNS Firewall-actioned domains (query logs)"
          region = var.aws_region
          query  = "SOURCE '${var.enable_resolver_query_logging ? aws_cloudwatch_log_group.resolver_query_log[0].name : ""}' | fields query_name, firewall_rule_action | filter ispresent(firewall_rule_action) and firewall_rule_action != 'NONE' | stats count(*) as hits by query_name, firewall_rule_action | sort hits desc | limit 25"
        }
      }
    ]
  })
}
