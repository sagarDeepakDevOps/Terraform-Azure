variable "name" {
  type        = string
  description = "Network security group name."
}

variable "resource_group_name" {
  type        = string
  description = "Existing resource group name."
}

variable "location" {
  type        = string
  description = "Azure region."
}

variable "rules" {
  type = map(object({
    priority                   = number
    direction                  = optional(string, "Inbound")
    access                     = optional(string, "Allow")
    protocol                   = optional(string, "Tcp")
    destination_port_range     = string
    source_address_prefix      = string
    destination_address_prefix = optional(string, "*")
  }))
  description = "Rules keyed by name; priorities must be unique within each direction."
  default     = {}
  validation {
    condition     = alltrue([for rule in var.rules : rule.priority >= 100 && rule.priority <= 4096])
    error_message = "NSG rule priorities must be between 100 and 4096."
  }
}

variable "subnet_ids" {
  type        = map(string)
  description = "Subnets to associate, keyed by stable names. Do not include GatewaySubnet or AzureFirewallSubnet."
  default     = {}
}

variable "tags" {
  type        = map(string)
  description = "Resource tags."
  default     = {}
}