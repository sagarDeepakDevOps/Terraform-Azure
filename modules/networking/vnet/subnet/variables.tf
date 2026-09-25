variable "name" {
  type        = string
  description = "Subnet name. AzureFirewallSubnet, AzureFirewallManagementSubnet, AzureBastionSubnet and GatewaySubnet are reserved names Azure services look for."
}

variable "resource_group_name" {
  type        = string
  description = "Resource group of the parent virtual network."
}

variable "virtual_network_name" {
  type        = string
  description = "Parent virtual network name."
}

variable "address_prefixes" {
  type        = list(string)
  description = "CIDR ranges inside the parent VNet's address space."

  validation {
    condition     = length(var.address_prefixes) > 0 && alltrue([for cidr in var.address_prefixes : can(cidrnetmask(cidr))])
    error_message = "Provide at least one valid IPv4 CIDR."
  }
}

variable "default_outbound_access_enabled" {
  type        = bool
  description = "False makes the subnet private: VMs get no implicit Internet egress and must use an explicit path such as a route to a firewall."
  default     = true
}
