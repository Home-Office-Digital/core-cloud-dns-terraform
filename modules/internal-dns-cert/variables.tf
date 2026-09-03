
variable "internal_domain_name" {
  description = "Single domain name used to create BOTH private and public hosted zones (e.g. np.internal.core.homeoffice.gov.uk)."
  type        = string
}

variable "internal_zone_id" {
  type = string
}

variable "tags" {
  description = "Tags to apply to created resources."
  type        = map(string)
  default     = {}
}

variable "additional_internal_zone_ids" {
  description = "A map of corresponding zone IDs with domain as the key"
  type        = map(string)
  default     = {}
}
