variable "name" {
  type        = string
  description = "Spoke short name, used in every resource name."
}

variable "name_prefix" {
  type        = string
  description = "Prefix for every resource name."
}

variable "resource_group_name" {
  type        = string
  description = "Existing resource group name."
}

variable "location" {
  type        = string
  description = "Azure region."
}

variable "address_space" {
  type        = list(string)
  description = "Spoke VNet CIDR ranges; must not overlap the hub or any other spoke."
}

variable "subnets" {
  type = map(object({
    address_prefixes = list(string)
    nsg_rules = optional(map(object({
      priority                     = number
      direction                    = optional(string, "Inbound")
      access                       = optional(string, "Allow")
      protocol                     = optional(string, "Tcp")
      source_address_prefixes      = list(string)
      destination_port_ranges      = optional(list(string), ["*"])
      destination_address_prefixes = optional(list(string), ["*"])
    })), {})
  }))
  description = "Subnets keyed by name, each with its own NSG rules."
}

variable "hub_vnet" {
  type = object({
    name                = string
    id                  = string
    resource_group_name = string
  })
  description = "Hub VNet to peer with."
}

variable "firewall_private_ip" {
  type        = string
  description = "Hub firewall private IP, the next hop of the spoke's default route."
}

variable "tags" {
  type        = map(string)
  description = "Resource tags."
  default     = {}
}
