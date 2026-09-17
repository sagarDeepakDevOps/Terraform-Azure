variable "resource_group_name" {
  type        = string
  description = "Resource group from exercise1."
}

variable "prefix" {
  type        = string
  description = "Same prefix used in exercise1."
}

variable "vnet_peerings" {
  type = map(object({
    first  = string
    second = string
  }))
  description = "Bidirectional peerings keyed by name. first and second are VNet short names from exercise2, and their address spaces must not overlap."
}
