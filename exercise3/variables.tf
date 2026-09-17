variable "resource_group_name" {
  type        = string
  description = "Resource group from exercise1."
}

variable "prefix" {
  type        = string
  description = "Same prefix used in exercise1, so the VNet names match what exercise2 created."
}

variable "vnet_subnets" {
  type = map(map(object({
    address_prefixes = list(string)
  })))
  description = "Subnets to create, grouped by the VNet short name used in exercise2. Each inner key becomes the Azure subnet name."

  validation {
    condition     = alltrue([for subnets in var.vnet_subnets : alltrue([for subnet in subnets : alltrue([for cidr in subnet.address_prefixes : can(cidrnetmask(cidr))])])])
    error_message = "Every address_prefixes entry must be a valid IPv4 CIDR, and must fit inside its VNet address space."
  }
}
