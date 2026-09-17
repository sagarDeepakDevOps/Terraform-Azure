variable "resource_group_name" {
  type        = string
  description = "Resource group from exercise1. Run terraform output resource_group_name there to get it."
}

variable "prefix" {
  type        = string
  description = "Same prefix used in exercise1."
}

variable "vnets" {
  type = map(object({
    address_space = list(string)
  }))
  description = "Virtual networks keyed by short name. Ranges must not overlap, or the peering in exercise5 is rejected."

  validation {
    condition     = alltrue([for vnet in var.vnets : alltrue([for cidr in vnet.address_space : can(cidrnetmask(cidr))])])
    error_message = "Every address_space entry must be a valid IPv4 CIDR."
  }
}

variable "tags" {
  type        = map(string)
  description = "Tags applied to every VNet."
  default     = {}
}
