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

variable "enable_r53_query_logging_length" {
  type        = number
  default     = 30
  description = "Length in days to store route53 query logs"
}
