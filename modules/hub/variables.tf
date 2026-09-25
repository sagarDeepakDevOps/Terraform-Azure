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
  description = "Hub VNet CIDR ranges; must not overlap any spoke."
}

variable "subnets" {
  type = map(object({
    address_prefixes   = list(string)
    route_via_firewall = optional(bool, false)
    nsg_rules = optional(map(object({
      priority                     = number
      direction                    = optional(string, "Inbound")
      access                       = optional(string, "Allow")
      protocol                     = optional(string, "Tcp")
      source_address_prefixes      = list(string)
      destination_port_ranges      = optional(list(string), ["*"])
      destination_address_prefixes = optional(list(string), ["*"])
    })))
  }))
  description = "Hub subnets keyed by name. AzureFirewallSubnet and AzureBastionSubnet are required, plus AzureFirewallManagementSubnet on the Basic tier. Give any other subnet nsg_rules to hold VMs."

  validation {
    condition     = contains(keys(var.subnets), "AzureFirewallSubnet") && contains(keys(var.subnets), "AzureBastionSubnet")
    error_message = "The hub needs subnets named AzureFirewallSubnet and AzureBastionSubnet."
  }

  validation {
    condition     = var.firewall_sku_tier != "Basic" || contains(keys(var.subnets), "AzureFirewallManagementSubnet")
    error_message = "The Basic firewall tier needs a subnet named AzureFirewallManagementSubnet."
  }

  validation {
    condition     = alltrue([for key, subnet in var.subnets : !contains(local.reserved_subnets, key) || (subnet.nsg_rules == null && !subnet.route_via_firewall)])
    error_message = "Reserved subnets (AzureFirewallSubnet, AzureFirewallManagementSubnet, AzureBastionSubnet, GatewaySubnet) cannot take nsg_rules or route_via_firewall."
  }
}

variable "firewall_sku_tier" {
  type        = string
  description = "Basic or Standard."
  default     = "Basic"
}

variable "firewall_dnat_rules" {
  type = map(object({
    destination_ports  = list(string)
    translated_address = string
    translated_port    = number
  }))
  description = "Inbound publishing rules on the firewall's public IP."
  default     = {}
}

variable "firewall_network_rules" {
  type = map(object({
    protocols             = list(string)
    source_addresses      = list(string)
    destination_addresses = list(string)
    destination_ports     = list(string)
  }))
  description = "Spoke-to-spoke allow rules."
  default     = {}
}

variable "firewall_application_rules" {
  type = map(object({
    source_addresses  = list(string)
    destination_fqdns = list(string)
    protocols = list(object({
      type = string
      port = number
    }))
  }))
  description = "Outbound FQDN allow rules for the spokes."
  default     = {}
}

variable "bastion_sku" {
  type        = string
  description = "Basic or Standard."
  default     = "Standard"
}

variable "tags" {
  type        = map(string)
  description = "Resource tags."
  default     = {}
}
