mock_provider "aws" {}

variables {
  tags = {
    Team = "network"
  }

  vpc_name = "network-vpc"
  vpc_id   = "vpc-1234567890abcdef0"

  poise_domain_names        = ["test-poise.example.local"]
  poise_dns_ips             = ["192.0.2.10", "192.0.2.11"]
  ebsa_notprod_domain_names = ["test-ebsa-notprod.example.local"]
  ebsa_prod_domain_names    = ["test-ebsa-prod.example.local"]
  ebsa_notprod_dns_ips      = ["198.51.100.10", "198.51.100.11"]
  ebsa_prod_dns_ips         = ["198.51.100.20", "198.51.100.21"]
  apa_hob_ibm_preprod_domain_names = ["test-ibm-preprod.example.local"]
  apa_hob_ibm_preprod_dns_ips      = ["203.0.113.10", "203.0.113.11"]
  apa_hob_ibm_prod_domain_names    = ["test-ibm-prod.example.local"]
  apa_hob_ibm_prod_dns_ips         = ["203.0.113.20", "203.0.113.21"]
  ncsc_dns_ips              = ["192.0.2.30", "192.0.2.31"]

  cc_aws_orgnisation_arn = "arn:aws:organizations::123456789012:organization/o-exampleorgid"

  domain_list_name  = "blocked-domains"
  domain_file_path  = "tests/domains.txt"
  rule_group_name   = "cc-dns-firewall"

  prod_cidrs    = ["10.10.0.0/16"]
  notprod_cidrs = ["10.20.0.0/16"]
  central_cidrs = ["10.30.0.0/16"]

  prod_transit_gateway_id    = "tgw-aaaaaaaaaaaaaaaaa"
  notprod_transit_gateway_id = "tgw-bbbbbbbbbbbbbbbbb"
  central_transit_gateway_id = "tgw-ccccccccccccccccc"

  poise_resolver_subnet_cidrs   = ["10.0.10.0/28", "10.0.10.16/28"]
  ncsc_resolver_subnet_cidrs    = ["10.0.20.0/28", "10.0.20.16/28"]
  natg_subnet_cidrs             = ["10.0.30.0/28", "10.0.30.16/28"]
  inbound_resolver_subnet_cidrs = ["10.0.40.0/28", "10.0.40.16/28"]
  availability_zones            = ["eu-west-2a", "eu-west-2b"]

  r53_ram_share_permission_arns = ["arn:aws:ram::aws:permission/AWSRAMPermissionRoute53ProfileAllowAssociation"]
}

run "plan_r53_profile" {
  command = plan

  assert {
    condition     = aws_route53profiles_profile.cc_r53_profile.name == "core-cloud-r53-profile"
    error_message = "Route53 profile name should remain stable."
  }

  assert {
    condition     = aws_route53profiles_association.network_vpc.resource_id == var.vpc_id
    error_message = "Network VPC association should target the supplied VPC ID."
  }

  assert {
    condition     = aws_route53_resolver_endpoint.cc_inbound_endpoint.direction == "INBOUND"
    error_message = "Inbound resolver endpoint direction must be INBOUND."
  }

  assert {
    condition     = aws_route53_resolver_endpoint.cc_poise_outbound_endpoint.direction == "OUTBOUND"
    error_message = "Poise resolver endpoint direction must be OUTBOUND."
  }

  assert {
    condition     = aws_route53_resolver_endpoint.cc_ncsc_outbound_endpoint.direction == "OUTBOUND"
    error_message = "NCSC resolver endpoint direction must be OUTBOUND."
  }

  assert {
    condition     = length(aws_route53_resolver_rule.poise) == length(var.poise_domain_names)
    error_message = "A POISE resolver rule should be created for each supplied POISE domain."
  }

  assert {
    condition     = length(aws_route53_resolver_rule.ebsa_notprod) == length(var.ebsa_notprod_domain_names)
    error_message = "An EBSA NOTPROD resolver rule should be created for each supplied domain."
  }

  assert {
    condition     = length(aws_route53_resolver_rule.ebsa_prod) == length(var.ebsa_prod_domain_names)
    error_message = "An EBSA PROD resolver rule should be created for each supplied domain."
  }

  assert {
    condition     = aws_route53_resolver_rule.cc_ncsc_resolver_rule.domain_name == "."
    error_message = "NCSC resolver rule should stay catch-all."
  }

  assert {
    condition     = aws_ram_resource_share.cc_r53_profile_share.allow_external_principals == false
    error_message = "RAM share should disallow external principals."
  }

  assert {
    condition     = aws_route53_resolver_firewall_rule_group_association.assoc.priority == var.rulegroup_association_priority
    error_message = "Firewall association priority should use the configured variable."
  }

  assert {
    condition     = alltrue([for r in aws_route53_resolver_firewall_rule.advanced_threat : r.action == "ALERT"])
    error_message = "Advanced detectors should default to ALERT when no per-detector action is set."
  }

  assert {
    condition     = length(aws_subnet.cc_inbound_endpoint_subnet) == length(var.inbound_resolver_subnet_cidrs)
    error_message = "Inbound subnet count should match inbound resolver CIDR count."
  }

  assert {
    condition     = length(aws_subnet.cc_poise_outbound_endpoint_subnet) == length(var.poise_resolver_subnet_cidrs)
    error_message = "Poise outbound subnet count should match configured CIDR count."
  }

  assert {
    condition     = length(aws_subnet.cc_ncsc_outbound_endpoint_subnet) == length(var.ncsc_resolver_subnet_cidrs)
    error_message = "NCSC outbound subnet count should match configured CIDR count."
  }

  assert {
    condition     = length(aws_nat_gateway.ncsc_natgw) == length(var.natg_subnet_cidrs)
    error_message = "NAT gateway count should match NAT subnet CIDR count."
  }

  assert {
    condition     = length(aws_route53_resolver_firewall_rule.aws_managed_rules) == 4
    error_message = "All four AWS managed firewall rules should be present."
  }

  assert {
    condition     = aws_ram_principal_association.cc_org_association.principal == var.cc_aws_orgnisation_arn
    error_message = "RAM principal association should use configured organization ARN."
  }
}

run "plan_advanced_per_detector_action_and_alarm" {
  command = plan

  variables {
    # DNS_TUNNELING overrides to BLOCK; DGA inherits the ALERT default.
    dns_firewall_advanced_action = "ALERT"
    dns_firewall_advanced_detectors = [
      { threat = "DNS_TUNNELING", priority = 50, action = "BLOCK" },
      { threat = "DGA", priority = 60 },
    ]
    # Point the dashboard/metric-filter at an external log group so the
    # query-log-derived advanced-detection alarm is created.
    enable_dns_firewall_alarms     = true
    dashboard_query_log_group_name = "external-resolver-query-logs"
  }

  assert {
    condition     = aws_route53_resolver_firewall_rule.advanced_threat["DNS_TUNNELING"].action == "BLOCK"
    error_message = "DNS_TUNNELING should use its per-detector BLOCK action."
  }

  assert {
    condition     = aws_route53_resolver_firewall_rule.advanced_threat["DNS_TUNNELING"].block_response == "NODATA"
    error_message = "A BLOCK detector should set block_response = NODATA."
  }

  assert {
    condition     = aws_route53_resolver_firewall_rule.advanced_threat["DGA"].action == "ALERT"
    error_message = "DGA should inherit the ALERT default when no per-detector action is set."
  }

  assert {
    condition     = aws_route53_resolver_firewall_rule.advanced_threat["DGA"].block_response == null
    error_message = "An ALERT detector should not set a block_response."
  }

  assert {
    condition     = length(aws_cloudwatch_log_metric_filter.advanced_detection) == 1
    error_message = "Advanced-detection metric filter should be created when a log group is configured and alarms are enabled."
  }

  assert {
    condition     = length(aws_cloudwatch_metric_alarm.advanced_detection) == 1
    error_message = "Advanced-detection alarm should be created when a log group is configured and alarms are enabled."
  }
}

run "plan_advanced_detection_alarm_skipped_without_log_group" {
  command = plan

  variables {
    enable_dns_firewall_alarms     = true
    enable_resolver_query_logging  = false
    dashboard_query_log_group_name = ""
  }

  assert {
    condition     = length(aws_cloudwatch_log_metric_filter.advanced_detection) == 0
    error_message = "Advanced-detection metric filter should be skipped when no query-log group is available."
  }

  assert {
    condition     = length(aws_cloudwatch_metric_alarm.advanced_detection) == 0
    error_message = "Advanced-detection alarm should be skipped when no query-log group is available."
  }
}

run "plan_r53_profile_without_optional_forwarding_domains" {
  command = plan

  variables {
    poise_domain_names        = []
    ebsa_notprod_domain_names = []
    ebsa_prod_domain_names    = []
    apa_hob_ibm_preprod_domain_names = []
    apa_hob_ibm_prod_domain_names    = []
  }

  assert {
    condition     = length(aws_route53_resolver_rule.poise) == 0
    error_message = "No POISE rules should be created when no POISE domains are provided."
  }

  assert {
    condition     = length(aws_route53_resolver_rule.ebsa_notprod) == 0
    error_message = "No EBSA NOTPROD rules should be created when no NOTPROD domains are provided."
  }

  assert {
    condition     = length(aws_route53_resolver_rule.ebsa_prod) == 0
    error_message = "No EBSA PROD rules should be created when no PROD domains are provided."
  }

  assert {
    condition     = aws_route53_resolver_rule.cc_ncsc_resolver_rule.domain_name == "."
    error_message = "Catch-all NCSC resolver rule should still be present."
  }
}
