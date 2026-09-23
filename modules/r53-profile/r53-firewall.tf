resource "aws_route53_resolver_firewall_domain_list" "custom_blocked_domains" {
  name    = var.domain_list_name
  domains = split("\n", file(var.domain_file_path))
  tags = merge(
    var.tags,
    {
      Environment = "prod"
      Account     = "Network"
      Component   = "r53-firewall"
    }
  )
}

resource "aws_route53_resolver_firewall_rule_group" "rule_group" {
  name = var.rule_group_name
  tags = merge(
    var.tags,
    {
      Environment = "prod"
      Account     = "Network"
      Component   = "r53-firewall"
    }
  )
}

# Add custom rules for - blocked domains
resource "aws_route53_resolver_firewall_rule" "custom_block_rule" {
  name                    = "cc-custom-block-rule"
  action                  = "BLOCK"
  block_response          = "NXDOMAIN"
  firewall_domain_list_id = aws_route53_resolver_firewall_domain_list.custom_blocked_domains.id
  priority                = var.custom_association_priority
  firewall_rule_group_id  = aws_route53_resolver_firewall_rule_group.rule_group.id
}


# Add all AWS managed lists
# fetched from aws console with cli:  aws route53resolver list-firewall-domain-lists --region eu-west-2
locals {
  aws_managed_lists = {
    AWSManagedDomainsMalwareDomainList         = "rslvr-fdl-4fc4edfc63854751"
    AWSManagedDomainsBotnetCommandandControl   = "rslvr-fdl-3268f74d91fe418f"
    AWSManagedDomainsAggregateThreatList       = "rslvr-fdl-4e96d4ce77f466b"
    AWSManagedDomainsAmazonGuardDutyThreatList = "rslvr-fdl-876a86d96f294739"
  }
}

resource "aws_route53_resolver_firewall_rule" "aws_managed_rules" {
  for_each = local.aws_managed_lists

  name                    = each.key
  action                  = "BLOCK"
  firewall_domain_list_id = each.value
  firewall_rule_group_id  = aws_route53_resolver_firewall_rule_group.rule_group.id
  priority                = var.aws_association_priority + index(keys(local.aws_managed_lists), each.key)
  block_response          = "NODATA"
}

# DNS Firewall Advanced — behavioural detection of DNS tunnelling / DGA.
#
# Unlike the domain-list rules above (feed/reputation based, which only catch
# KNOWN-bad domains), Advanced rules inspect DNS query behaviour (entropy,
# length, rate, timing) in real time and can flag PREVIOUSLY UNKNOWN domains —
# the uncategorised-attacker-domain exfiltration vector that NCSC PDNS does not
# behaviourally detect. See core-cloud-dns-terragrunt#122.
#
# Requires AWS provider >= 6.28.0 (dns_threat_protection / confidence_threshold).
# Advanced rules support only BLOCK or ALERT (no ALLOW). Default to ALERT so we
# observe + tune before ever blocking on a resolver that fronts the whole estate.
#
# One rule per enabled detector; priorities come lowest-first so Advanced
# evaluates ahead of the managed (200+) and custom (300) domain-list rules.
resource "aws_route53_resolver_firewall_rule" "advanced_threat" {
  for_each = { for d in var.dns_firewall_advanced_detectors : d.threat => d }

  name                   = "cc-adv-${lower(each.value.threat)}"
  action                 = var.dns_firewall_advanced_action
  firewall_rule_group_id = aws_route53_resolver_firewall_rule_group.rule_group.id
  priority               = each.value.priority

  dns_threat_protection = each.value.threat
  confidence_threshold  = var.dns_firewall_advanced_confidence_threshold

  # NODATA only applies when blocking; harmless/ignored for ALERT.
  block_response = var.dns_firewall_advanced_action == "BLOCK" ? "NODATA" : null
}

# rule-group association
resource "aws_route53_resolver_firewall_rule_group_association" "assoc" {
  name                   = "${var.rule_group_name}-assoc"
  firewall_rule_group_id = aws_route53_resolver_firewall_rule_group.rule_group.id
  priority               = var.rulegroup_association_priority
  vpc_id                 = var.vpc_id
  mutation_protection    = "DISABLED"
  tags = merge(
    var.tags,
    {
      Environment = "prod"
      Account     = "Network"
      Component   = "r53-firewall"
    }
  )
}


