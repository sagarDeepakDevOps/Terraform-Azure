variable "name" {
  type        = string
  description = "Domain zone name. Owning an Azure DNS zone does not register or delegate the domain."
}

variable "resource_group_name" {
  type        = string
  description = "Existing resource group name."
}

variable "a_records" {
  type        = map(list(string))
  description = "Relative record names mapped to IPv4 addresses."
  default     = {}
}

variable "cname_records" {
  type        = map(string)
  description = "Relative record names mapped to target FQDNs. TLS/custom-domain binding is a separate step."
  default     = {}
}

variable "tags" {
  type        = map(string)
  description = "Resource tags."
  default     = {}
}