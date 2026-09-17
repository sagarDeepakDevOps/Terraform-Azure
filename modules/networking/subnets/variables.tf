variable "resource_group_name" {
  type        = string
  description = "Resource group containing the VNet."
}

variable "virtual_network_name" {
  type        = string
  description = "Existing VNet name."
}

variable "subnets" {
  type = map(object({
    address_prefixes                  = list(string)
    service_endpoints                 = optional(list(string), [])
    private_endpoint_network_policies = optional(string, "Disabled")
    delegation = optional(object({
      name         = string
      service_name = string
      actions      = optional(list(string), ["Microsoft.Network/virtualNetworks/subnets/action"])
    }))
  }))
  description = "Subnet definitions. Reserved Azure subnet names must retain their required names and sizes."
}