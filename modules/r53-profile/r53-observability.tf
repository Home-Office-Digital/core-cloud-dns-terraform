###############################################################################
# DNS observability — CloudWatch alarms + dashboard (+ optional query logging)
#
# Purpose: make DNS Firewall Advanced ALERT mode actionable — alarm on match
# volume and surface DNS-Firewall-actioned domains on a dashboard.
#
# Query logging: OFF by default. In estates where the VPC already has managed
# Resolver query logging (e.g. AWS Landing Zone Accelerator associates an
# org-wide query-log config), this module must NOT create its own — Route 53
# allows only one query-log association per VPC per destination type, so a
# second one fails with RSLVR-01306. Point the dashboard at the existing log
# group via var.dashboard_query_log_group_name instead. Only enable
# enable_resolver_query_logging where no such managed logging exists.
###############################################################################

data "aws_caller_identity" "current" {}
data "aws_region" "current" {}

locals {
  # Log group the dashboard's Logs Insights panel reads DNS Firewall actions
  # from. Prefer an externally-managed group (e.g. the LZA query-log group);
  # else this module's own group when it manages logging; else empty.
  dashboard_log_group = (
    var.dashboard_query_log_group_name != "" ? var.dashboard_query_log_group_name :
    var.enable_resolver_query_logging ? aws_cloudwatch_log_group.resolver_query_log[0].name :
    ""
  )
}

########################################
# Resolver query logging -> CloudWatch (KMS-encrypted)
# OFF by default — only for estates without managed (e.g. LZA) query logging.
########################################

# KMS key to encrypt the Resolver query log group (CKV_AWS_158). Mirrors the
# r53-public-zone query-log key convention: CloudWatch Logs service principal
# allowed, scoped via the encryption-context condition to this log-group path.
resource "aws_kms_key" "resolver_query_log_key" {
  count = var.enable_resolver_query_logging ? 1 : 0

  description             = "KMS key for Route 53 Resolver query log encryption (${var.vpc_name})"
  enable_key_rotation     = true
  deletion_window_in_days = 7

  # The apply role (assumed via OIDC) creates the key but is not itself named as
  # a policy principal; KMS's CreateKey lockout check then rejects the policy
  # ("will not allow you to update the key policy in the future"), even though
  # the account root retains kms:* here. Account IAM (via the root statement)
  # can still administer the key, so bypass the per-call lockout safety check.
  # See https://repost.aws/knowledge-center/update-key-policy-future
  bypass_policy_lockout_safety_check = true

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
# Advanced-detection alarm via query-log metric filter
#
# The AWS/Route53Resolver FirewallRuleGroupQueryVolume metric only counts
# DOMAIN-LIST rule matches — it does NOT emit for Advanced (dns_threat_protection)
# rules (DNS_TUNNELING / DGA / DICTIONARY_DGA). Confirmed empirically: 80+ ALERTs
# in the query logs produced zero metric datapoints (core-cloud-dns-terragrunt#122).
#
# So for Advanced-detection alerting we derive a custom metric from the Resolver
# query logs instead: a metric filter matches log events whose firewall_rule_action
# is ALERT or BLOCK, and an alarm fires on that metric. This reads the same log
# group the dashboard uses (typically the externally-managed LZA query-log group).
#
# Requires a readable query-log group (local.dashboard_log_group). If none is
# configured, the filter/alarm are skipped.
########################################

locals {
  # Only create the Advanced-detection metric filter/alarm when we have a log
  # group to read and alarms are enabled.
  enable_advanced_detection_alarm = var.enable_dns_firewall_alarms && local.dashboard_log_group != ""

  advanced_detection_metric_namespace = "CoreCloud/DNSFirewall"
  advanced_detection_metric_name      = "${var.rule_group_name}-advanced-detection-matches"
}

resource "aws_cloudwatch_log_metric_filter" "advanced_detection" {
  count = local.enable_advanced_detection_alarm ? 1 : 0

  name           = "cc-dns-firewall-${var.rule_group_name}-advanced-detection"
  log_group_name = local.dashboard_log_group

  # Route 53 Resolver query logs are JSON. firewall_rule_action is populated
  # only when a firewall rule (domain-list OR Advanced) matched with alert/block.
  # Advanced detections surface here even though they don't emit the native
  # CloudWatch metric. Match ALERT or BLOCK.
  pattern = "{ ($.firewall_rule_action = \"ALERT\") || ($.firewall_rule_action = \"BLOCK\") }"

  metric_transformation {
    name          = local.advanced_detection_metric_name
    namespace     = local.advanced_detection_metric_namespace
    value         = "1"
    default_value = "0"
    unit          = "Count"
  }
}

resource "aws_cloudwatch_metric_alarm" "advanced_detection" {
  count = local.enable_advanced_detection_alarm ? 1 : 0

  alarm_name          = "cc-dns-firewall-${var.rule_group_name}-advanced-detection"
  alarm_description   = "DNS Firewall Advanced detection (DNS_TUNNELING / DGA / DICTIONARY_DGA) matched a query in ALERT or BLOCK mode. Derived from Resolver query logs because the native FirewallRuleGroupQueryVolume metric does not cover Advanced rules. Inspect the query logs (firewall_rule_action) to attribute. See core-cloud-dns-terragrunt#122."
  namespace           = local.advanced_detection_metric_namespace
  metric_name         = local.advanced_detection_metric_name
  statistic           = "Sum"
  comparison_operator = "GreaterThanThreshold"
  threshold           = var.dns_firewall_alarm_threshold
  period              = 300
  evaluation_periods  = 1
  treat_missing_data  = "notBreaching"

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

  dashboard_name = "cc-dns-${var.vpc_name}"

  dashboard_body = jsonencode({
    widgets = concat([
      # ── Title banner ──────────────────────────────────────────────────────
      {
        type = "text", x = 0, y = 0, width = 24, height = 2
        properties = {
          markdown = "# 🛡️ Core Cloud DNS — Firewall & Resolver\n**Estate-wide DNS view** for the network hub (`${var.vpc_name}`, ${var.aws_region}) · firewall detections · PDNS/POISE forwarding · resolver health · query-log drilldowns.\n\n*Tip: set the console to Dark mode via the top-right display settings. Advanced-detection panels use the query logs — click a panel's expand icon to open in Logs Insights.*"
        }
      },
      # ── Headline tiles ────────────────────────────────────────────────────
      {
        type = "metric", x = 0, y = 2, width = 12, height = 4
        properties = {
          title     = "Domain-list blocks (last 5m)"
          region    = var.aws_region
          view      = "singleValue"
          sparkline = true
          stat      = "Sum"
          period    = 300
          metrics = [
            ["AWS/Route53Resolver", "FirewallRuleGroupQueryVolume", "FirewallRuleGroupId", aws_route53_resolver_firewall_rule_group.rule_group.id, { label = "Domain-list matches", color = "#1f77b4" }]
          ]
        }
      },
      {
        type = "metric", x = 12, y = 2, width = 12, height = 4
        properties = {
          title     = "Advanced detections — tunnelling / DGA (last 5m)"
          region    = var.aws_region
          view      = "singleValue"
          sparkline = true
          stat      = "Sum"
          period    = 300
          metrics = local.enable_advanced_detection_alarm ? [
            [local.advanced_detection_metric_namespace, local.advanced_detection_metric_name, { label = "Advanced detections", color = "#d62728" }]
          ] : []
        }
      },
      # ── Firewall section ──────────────────────────────────────────────────
      {
        type       = "text", x = 0, y = 6, width = 24, height = 1
        properties = { markdown = "## 🚨 Firewall detections" }
      },
      {
        type = "metric", x = 0, y = 7, width = 12, height = 6
        properties = {
          title   = "Firewall match volume — domain-list vs Advanced"
          region  = var.aws_region
          view    = "timeSeries"
          stacked = false
          stat    = "Sum"
          period  = 300
          yAxis   = { left = { min = 0 } }
          annotations = {
            horizontal = [
              { label = "alarm threshold", value = var.dns_firewall_alarm_threshold, color = "#d62728" }
            ]
          }
          metrics = concat(
            [
              ["AWS/Route53Resolver", "FirewallRuleGroupQueryVolume", "FirewallRuleGroupId", aws_route53_resolver_firewall_rule_group.rule_group.id, { label = "Domain-list rules", color = "#1f77b4" }]
            ],
            local.enable_advanced_detection_alarm ? [
              [local.advanced_detection_metric_namespace, local.advanced_detection_metric_name, { label = "Advanced (tunnelling/DGA)", color = "#d62728" }]
            ] : []
          )
        }
      },
      {
        type = "metric", x = 12, y = 7, width = 12, height = 6
        properties = {
          title  = "Resolver endpoint health (healthy ENIs)"
          region = var.aws_region
          view   = "gauge"
          stat   = "Minimum"
          period = 300
          yAxis  = { left = { min = 0, max = 4 } }
          annotations = {
            horizontal = [
              { label = "degraded", value = 0, fill = "below", color = "#d62728" },
              { label = "ok", value = 2, fill = "above", color = "#2ca02c" }
            ]
          }
          metrics = [
            ["AWS/Route53Resolver", "EndpointHealthyENICount", "EndpointId", aws_route53_resolver_endpoint.cc_inbound_endpoint.id, { label = "Inbound", color = "#1f77b4" }],
            ["AWS/Route53Resolver", "EndpointHealthyENICount", "EndpointId", aws_route53_resolver_endpoint.cc_ncsc_outbound_endpoint.id, { label = "NCSC outbound", color = "#9467bd" }],
            ["AWS/Route53Resolver", "EndpointHealthyENICount", "EndpointId", aws_route53_resolver_endpoint.cc_poise_outbound_endpoint.id, { label = "POISE outbound", color = "#ff7f0e" }]
          ]
        }
      },
      # ── Resolver traffic section ──────────────────────────────────────────
      {
        type       = "text", x = 0, y = 13, width = 24, height = 1
        properties = { markdown = "## 🌐 Resolver query volume" }
      },
      {
        type = "metric", x = 0, y = 14, width = 12, height = 6
        properties = {
          title  = "Outbound — PDNS / POISE forwarding"
          region = var.aws_region
          view   = "timeSeries"
          stat   = "Sum"
          period = 300
          yAxis  = { left = { min = 0 } }
          metrics = [
            ["AWS/Route53Resolver", "OutboundQueryVolume", "EndpointId", aws_route53_resolver_endpoint.cc_ncsc_outbound_endpoint.id, { label = "NCSC PDNS outbound", color = "#9467bd" }],
            ["AWS/Route53Resolver", "OutboundQueryVolume", "EndpointId", aws_route53_resolver_endpoint.cc_poise_outbound_endpoint.id, { label = "POISE outbound", color = "#ff7f0e" }]
          ]
        }
      },
      {
        type = "metric", x = 12, y = 14, width = 12, height = 6
        properties = {
          title  = "Inbound query volume"
          region = var.aws_region
          view   = "timeSeries"
          stat   = "Sum"
          period = 300
          yAxis  = { left = { min = 0 } }
          metrics = [
            ["AWS/Route53Resolver", "InboundQueryVolume", "EndpointId", aws_route53_resolver_endpoint.cc_inbound_endpoint.id, { label = "Inbound endpoint", color = "#1f77b4" }]
          ]
        }
      },
      # ── Query-log drilldowns section ──────────────────────────────────────
      {
        type       = "text", x = 0, y = 20, width = 24, height = 1
        properties = { markdown = "## 🔎 Query-log drilldowns" }
      },
      {
        type = "log", x = 0, y = 21, width = 24, height = 6
        properties = {
          title  = "Top DNS Firewall-actioned domains (query logs)"
          region = var.aws_region
          query  = "SOURCE '${local.dashboard_log_group}' | fields query_name, firewall_rule_action | filter ispresent(firewall_rule_action) and firewall_rule_action != 'NONE' | stats count(*) as hits by query_name, firewall_rule_action | sort hits desc | limit 25"
        }
      }
      ],
      # Advanced-detections log widgets — raw events, top source IPs, and a
      # per-detector breakdown. Let a spike on the metric panel be inspected
      # query-by-query (use each widget's "open in Logs Insights" action to
      # drill in with the dashboard time range). Only shown when a readable
      # query-log group is configured.
      #
      # Advanced detections are identified by an ALERT/BLOCK action where
      # firewall_domain_list_id is the literal string "EMPTY": domain-list rules
      # populate that field with an rslvr-fdl-* id, while dns_threat_protection
      # (Advanced) rules record it as "EMPTY" (the field is present with value
      # "EMPTY", not absent/empty-string).
      #
      # The query logs ALSO record which detector fired in the firewall_protection
      # field (DNS_TUNNELING / DGA / DICTIONARY_DGA), so detections can be
      # attributed per-detector directly from the logs — no separate rule groups
      # needed. The per-detector breakdown widget uses this to inform the
      # ALERT->BLOCK decision.
      local.dashboard_log_group != "" ? [
        {
          type       = "text", x = 0, y = 27, width = 24, height = 1
          properties = { markdown = "## 🧬 Advanced detections (behavioural) — detector attribution & triage" }
        },
        {
          type = "log", x = 0, y = 28, width = 24, height = 6
          properties = {
            title  = "DNS Firewall Advanced detections — raw events (detector / query / source)"
            region = var.aws_region
            query  = "SOURCE '${local.dashboard_log_group}' | fields @timestamp, firewall_protection, query_name, firewall_rule_action, srcaddr | filter (firewall_rule_action = 'ALERT' or firewall_rule_action = 'BLOCK') and firewall_domain_list_id = 'EMPTY' | sort @timestamp desc | limit 100"
          }
        },
        # Top source IPs for Advanced detections — turns "something is noisy"
        # into "this host is noisy", which is what false-positive triage needs
        # (e.g. an internal service doing short/compound-label lookups). Grouped
        # by detector (firewall_protection) too, so FP noise can be attributed.
        # The detections:distinct_queries ratio is the triage signal — a high
        # count with few distinct names is benign repetition; a ~1:1 ratio of
        # detections to distinct names is the tunnelling/DGA signature.
        {
          type = "log", x = 0, y = 34, width = 24, height = 6
          properties = {
            title  = "DNS Firewall Advanced detections — top source IPs (by detector)"
            region = var.aws_region
            query  = "SOURCE '${local.dashboard_log_group}' | fields srcaddr, query_name, firewall_protection | filter (firewall_rule_action = 'ALERT' or firewall_rule_action = 'BLOCK') and firewall_domain_list_id = 'EMPTY' | stats count(*) as detections, count_distinct(query_name) as distinct_queries by srcaddr, firewall_protection | sort detections desc | limit 25"
          }
        },
        # Per-detector breakdown — counts and distinct-name counts by detector
        # (DNS_TUNNELING / DGA / DICTIONARY_DGA). This is the view that informs
        # the ALERT->BLOCK decision: a detector dominated by many detections but
        # few distinct names, or by NXDOMAIN/known-good names, is FP-prone and
        # should stay in ALERT. firewall_protection is the per-detector field
        # the Resolver query logs record for Advanced detections.
        {
          type = "log", x = 0, y = 40, width = 24, height = 6
          properties = {
            title  = "DNS Firewall Advanced detections — per-detector breakdown"
            region = var.aws_region
            query  = "SOURCE '${local.dashboard_log_group}' | fields firewall_protection, query_name, srcaddr | filter (firewall_rule_action = 'ALERT' or firewall_rule_action = 'BLOCK') and firewall_domain_list_id = 'EMPTY' | stats count(*) as detections, count_distinct(query_name) as distinct_names, count_distinct(srcaddr) as source_hosts by firewall_protection | sort detections desc"
          }
        }
      ] : []
    )
  })
}
