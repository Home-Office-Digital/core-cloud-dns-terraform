
variable "vpc_name" {
  description = "Value of the VPC 'Name' tag used to look up the VPC ID."
  type        = string
}

variable "internal_domain_name" {
  description = "Single domain name used to create BOTH private and public hosted zones (e.g. np.internal.core.homeoffice.gov.uk)."
  type        = string
}

variable "additional_internal_domain_names" {
  description = "Additional domain names used to create BOTH private and public hosted zones (e.g. np.internal.core.homeoffice.gov.uk)."
  type        = list(string)
  default     = []
}

variable "route53_profile_id" {
  description = "Route 53 Profile ID to associate the VPC and PHZ with. Pass via GitHub env var TF_VAR_route53_profile_id."
  type        = string
}

variable "enable_dnssec" {
  type        = bool
  default     = false
  description = "Enable Route53 DNSSEC signing"
}

variable "enable_r53_query_logging" {
  type        = bool
  default     = false
  description = "Enable Route53 Query Logging"
}

variable "enable_r53_query_logging_length" {
  type        = number
  default     = 30
  description = "Length in days to store route53 query logs"
}


variable "tags" {
  description = "Tags to apply to created resources."
  type        = map(string)
  default     = {}
}