variable "workload_public_zone_ns_records" {
  description = "List of external name servers for the workload public zone"
  type        = list(string)
  default = [
    "ns-1234.awsdns-33.org.",
    "ns-1234.awsdns-15.net.",
    "ns-1234.awsdns-25.co.uk.",
    "ns-1234.awsdns-45.com."
  ]
}

variable "zone_id" {
  description = "The Route 53 hosted zone ID where the NS record should be created"
  type        = string
}

variable "domain_name" {
  description = "The domain name for which the NS record will be created"
  type        = string
}

variable "additional_name_servers" {
  description = "Map of additional child domain name => that domain's own NS records (list), sourced from the r53-public-zone module's additional_name_servers output."
  type        = map(list(string))
  default     = {}
}
