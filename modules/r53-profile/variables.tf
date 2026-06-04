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
  type        = list(string)
}
