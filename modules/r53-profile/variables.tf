######
# Shared
######


variable "tags" {
  type        = map(string)
  description = "Tags to apply to AWS resources"
}


variable "vpc_name" {
  description = "VPC Name"
  type        = string
}

variable "vpc_id" {
  description = "VPC ID of the network account where the Route 53 profile will be associated"
  type        = string
}


variable "poise_domain_names" {
  type = list(string)
  # example:
  # default = ["poise.homeoffice.local", "immigrationservices.phz"]
}

variable "poise_dns_ips" {
  type = list(string)
  # example:
  # default = ["10.228.8.69", "10.228.9.69"]
}

variable "ebsa_notprod_domain_names" {
  type = list(string)
}

variable "ebsa_prod_domain_names" {
  type = list(string)
}

variable "ebsa_notprod_dns_ips" {
  type = list(string)
  # example:
  # default = ["10.223.6.134", "10.223.6.6"]
}

variable "ebsa_prod_dns_ips" {
  type = list(string)
  # example:
  # default = ["10.223.2.134", "10.223.2.6"]
}

variable "apa_hob_ibm_preprod_domain_names" {
  type = list(string)
  # example:
  # default = ["bmps.homeoffice.gov.uk"]
}

variable "apa_hob_ibm_preprod_dns_ips" {
  type = list(string)
}

variable "apa_hob_ibm_prod_domain_names" {
  type = list(string)
  # example:
  # default = ["bmps.homeoffice.gov.uk"]
}

variable "apa_hob_ibm_prod_dns_ips" {
  type = list(string)
}

variable "ncsc_domain_names" {
  description = "List of domain names to forward explicitly via NCSC PDNS outbound endpoint"
  type        = list(string)
  default     = []
}

variable "ncsc_dns_ips" {
  description = "List of NCSC PDNS IP addresses"
  type        = list(string)
  # example:
  # default = ["10.228.10.10", "10.228.11.10"]
}


variable "cc_aws_orgnisation_arn" {
  description = "Core Cloud AWS Org ARN"
  type        = string
}


##################
## r53-firewall ##
##################
variable "domain_list_name" {
  description = "Name for the domain list"
  type        = string
}

variable "domain_file_path" {
  description = "Path to the domain list text file"
  type        = string
}

variable "rule_group_name" {
  description = "DNS Firewall Rule Group name"
  type        = string
}

variable "aws_association_priority" {
  description = "Priority for rule group association"
  type        = number
  default     = 200
}

variable "custom_association_priority" {
  description = "Priority for rule group association"
  type        = number
  default     = 300
}

variable "rulegroup_association_priority" {
  description = "Priority for rule group association"
  type        = number
  default     = 100
}

# DNS Firewall Advanced (behavioural DNS tunnelling / DGA detection).
# Requires AWS provider >= 6.28.0.
variable "dns_firewall_advanced_detectors" {
  description = <<-EOT
    DNS Firewall Advanced threat detectors to create, each as an object with:
      threat   - one of "DNS_TUNNELING", "DGA", "DICTIONARY_DGA"
      priority - rule priority (lowest evaluated first; keep below the managed
                 (200+) and custom (300) domain-list rule priorities)
      action   - (optional) "ALERT" or "BLOCK" for THIS detector. Omit/null to
                 use var.dns_firewall_advanced_action as the default. This lets
                 a validated detector (e.g. DNS_TUNNELING) move to BLOCK while
                 less-certain ones (DGA, DICTIONARY_DGA) stay in ALERT.
    Set to [] to disable Advanced rules entirely.
  EOT
  type = list(object({
    threat   = string
    priority = number
    action   = optional(string)
  }))
  default = [
    { threat = "DNS_TUNNELING", priority = 50 },
    { threat = "DGA", priority = 60 },
  ]

  validation {
    condition = alltrue([
      for d in var.dns_firewall_advanced_detectors :
      contains(["DNS_TUNNELING", "DGA", "DICTIONARY_DGA"], d.threat)
    ])
    error_message = "Each threat must be one of DNS_TUNNELING, DGA, or DICTIONARY_DGA."
  }

  validation {
    condition = alltrue([
      for d in var.dns_firewall_advanced_detectors :
      d.action == null ? true : contains(["ALERT", "BLOCK"], d.action)
    ])
    error_message = "Each detector action, when set, must be ALERT or BLOCK (ALLOW is not supported for Advanced rules)."
  }
}

variable "dns_firewall_advanced_action" {
  description = "Default action for DNS Firewall Advanced rules that do not set a per-detector action. ALERT (monitor) or BLOCK. Start with ALERT and switch a detector to BLOCK only after tuning (set per-detector via dns_firewall_advanced_detectors[].action)."
  type        = string
  default     = "ALERT"

  validation {
    condition     = contains(["ALERT", "BLOCK"], var.dns_firewall_advanced_action)
    error_message = "dns_firewall_advanced_action must be ALERT or BLOCK (ALLOW is not supported for Advanced rules)."
  }
}

variable "dns_firewall_advanced_confidence_threshold" {
  description = "Confidence threshold for DNS Firewall Advanced detection: LOW, MEDIUM, or HIGH."
  type        = string
  default     = "MEDIUM"

  validation {
    condition     = contains(["LOW", "MEDIUM", "HIGH"], var.dns_firewall_advanced_confidence_threshold)
    error_message = "dns_firewall_advanced_confidence_threshold must be LOW, MEDIUM, or HIGH."
  }
}

######################
## Observability
######################

variable "enable_resolver_query_logging" {
  description = "Create a Route 53 Resolver query log config -> CloudWatch and associate it with the VPC. Leave false where the VPC already has managed query logging (e.g. AWS LZA associates an org-wide config) — Route 53 allows only one association per VPC per destination type, so a second fails with RSLVR-01306. When false, set dashboard_query_log_group_name to the existing group."
  type        = bool
  default     = false
}

variable "dashboard_query_log_group_name" {
  description = "Name of an existing Resolver query-log CloudWatch log group for the dashboard's Logs Insights panel to read (e.g. the AWS LZA query-log group). Used when enable_resolver_query_logging is false. Empty = use this module's own group (only valid when logging is enabled)."
  type        = string
  default     = ""
}

variable "resolver_query_log_retention_days" {
  description = "CloudWatch Logs retention (days) for the Resolver query log group. Default 365 to satisfy CKV_AWS_338 (>= 1 year)."
  type        = number
  default     = 365
}

variable "enable_dns_firewall_alarms" {
  description = "Create CloudWatch alarms on DNS Firewall Advanced rule matches (one per detector)."
  type        = bool
  default     = true
}

variable "dns_firewall_alarm_threshold" {
  description = "Threshold (matched query count per 5-minute period) above which the Advanced-rule alarm fires."
  type        = number
  default     = 1
}

variable "dns_firewall_alarm_sns_topic_arn" {
  description = "Optional SNS topic ARN for alarm/ok actions. Empty string = no notification action (alarm still visible in CloudWatch)."
  type        = string
  default     = ""
}

variable "enable_dns_dashboard" {
  description = "Create a CloudWatch dashboard for the central DNS hub (firewall match volume, endpoint query volume/health, top actioned domains)."
  type        = bool
  default     = true
}

variable "aws_region" {
  description = "AWS region, used for CloudWatch dashboard widget metric/log queries."
  type        = string
  default     = "eu-west-2"
}


######
# Routing
######

variable "prod_cidrs" {
  description = "List of CIDRs reachable via the PROD Transit Gateway"
  type        = list(string)
  default     = []
}

variable "notprod_cidrs" {
  description = "List of CIDRs reachable via the NOTPROD Transit Gateway"
  type        = list(string)
  default     = []
}

variable "central_cidrs" {
  description = "List of CIDRs reachable via the CENTRAL Transit Gateway"
  type        = list(string)
  default     = []
}

variable "prod_transit_gateway_id" {
  description = "Transit Gateway ID for PROD (e.g., tgw-xxxxxxxxxxxxxxxxx)"
  type        = string
}

variable "notprod_transit_gateway_id" {
  description = "Transit Gateway ID for NOTPROD"
  type        = string
}

variable "central_transit_gateway_id" {
  description = "Transit Gateway ID for CENTRAL"
  type        = string
}


variable "poise_resolver_subnet_cidrs" {
  type        = list(string)
  description = "List of CIDRs for Poise outbound resolver subnets"
}

variable "ncsc_resolver_subnet_cidrs" {
  type        = list(string)
  description = "List of CIDRs for NCSC outbound resolver subnets"
}

variable "natg_subnet_cidrs" {
  type        = list(string)
  description = "List of CIDRs for NCSC outbound resolver subnets"
}

variable "inbound_resolver_subnet_cidrs" {
  type        = list(string)
  description = "List of CIDRs for inbound resolver subnets"
}

variable "availability_zones" {
  type        = list(string)
  description = "List of availability zones"
}

variable "r53_ram_share_permission_arns" {
  type = list(string)
}
