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
# Resolver query logging -> CloudWatch
########################################

resource "aws_cloudwatch_log_group" "resolver_query_log" {
  count = var.enable_resolver_query_logging ? 1 : 0

  name              = "/aws/route53resolver/${var.vpc_name}-query-logs"
  retention_in_days = var.resolver_query_log_retention_days

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
# CloudWatch alarms on DNS Firewall Advanced rule matches
#
# One alarm per configured Advanced detector. DNS Firewall publishes match
# counts to AWS/Route53Resolver; we alarm on a sustained spike so ALERT-mode
# detections are surfaced even before anyone reads the query logs.
########################################

resource "aws_cloudwatch_metric_alarm" "advanced_rule_match" {
  for_each = var.enable_dns_firewall_alarms ? { for d in var.dns_firewall_advanced_detectors : d.threat => d } : {}

  alarm_name          = "cc-dns-firewall-adv-${lower(each.value.threat)}-matches"
  alarm_description   = "DNS Firewall Advanced ${each.value.threat} rule matched queries (rule group ${var.rule_group_name}). Investigate potential ${each.value.threat} activity."
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
    Rule                = aws_route53_resolver_firewall_rule.advanced_threat[each.key].name
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
