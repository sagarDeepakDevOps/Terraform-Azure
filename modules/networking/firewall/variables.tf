variable "name" {
  type        = string
  description = "Firewall name; the policy and public IPs are named after it."
}

variable "resource_group_name" {
  type        = string
  description = "Existing resource group name."
}

variable "location" {
  type        = string
  description = "Azure region."
}

variable "sku_tier" {
  type        = string
  description = "Basic is the cheapest tier and needs a management subnet and IP. Standard adds DNS proxy and threat-intel deny mode."
  default     = "Basic"

  validation {
    condition     = contains(["Basic", "Standard"], var.sku_tier)
    error_message = "sku_tier must be Basic or Standard."
  }
}

variable "subnet_id" {
  type        = string
  description = "ID of the subnet named AzureFirewallSubnet, at least /26."
}

variable "management_subnet_id" {
  type        = string
  description = "ID of the subnet named AzureFirewallManagementSubnet, at least /26. Required for the Basic tier, ignored otherwise."
  default     = null

  validation {
    condition     = var.sku_tier != "Basic" || var.management_subnet_id != null
    error_message = "The Basic tier needs management_subnet_id."
  }
}

variable "dnat_rules" {
  type = map(object({
    protocols          = optional(list(string), ["TCP"])
    source_addresses   = optional(list(string), ["*"])
    destination_ports  = list(string)
    translated_address = string
    translated_port    = number
  }))
  description = "Inbound DNAT rules; each maps a port on the firewall's public IP to a private address and port."
  default     = {}
}

variable "network_rules" {
  type = map(object({
    protocols             = list(string)
    source_addresses      = list(string)
    destination_addresses = list(string)
    destination_ports     = list(string)
  }))
  description = "Layer-4 allow rules."
  default     = {}
}

variable "application_rules" {
  type = map(object({
    source_addresses  = list(string)
    destination_fqdns = list(string)
    protocols = list(object({
      type = string
      port = number
    }))
  }))
  description = "Outbound FQDN allow rules."
  default     = {}
}

variable "tags" {
  type        = map(string)
  description = "Resource tags."
  default     = {}
}
