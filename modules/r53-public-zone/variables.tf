variable "domain_name" {
  description = "The domain name for the Route 53 hosted zone"
  type        = string
}

variable "additional_domain_names" {
  description = "A list of additional Route 53 hosted zones"
  type        = list(string)
  default     = []
}

variable "environment" {
  description = "The environment in which the hosted zone is deployed"
  type        = string
}

variable "tags" {
  description = "Additional tags to be applied to the hosted zone"
  type        = map(string)
  default     = {}
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
