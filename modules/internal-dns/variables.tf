
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

variable "r53_query_logging_length" {
  type        = number
  default     = 365
  description = "Length in days to store route53 query logs. Must be a value supported by CloudWatch Logs retention."

  validation {
    condition = contains(
      [0, 1, 3, 5, 7, 14, 30, 60, 90, 120, 150, 180, 365, 400, 545, 731, 1096, 1827, 2192, 2557, 2922, 3288, 3653],
      var.r53_query_logging_length
    )
    error_message = "r53_query_logging_length must be a valid CloudWatch Logs retention value (e.g. 30, 90, 365, 400, 731)."
  }
}


variable "tags" {
  description = "Tags to apply to created resources."
  type        = map(string)
  default     = {}
}