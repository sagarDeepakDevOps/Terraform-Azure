variable "resource_group_name" {
  type        = string
  description = "Resource group from exercise1."
}

variable "prefix" {
  type        = string
  description = "Same prefix used in exercise1."
}

variable "nsgs" {
  type = map(object({
    vnet_key    = string
    subnet_name = string
    rules = map(object({
      priority                   = number
      direction                  = optional(string, "Inbound")
      access                     = optional(string, "Allow")
      protocol                   = optional(string, "Tcp")
      destination_port_range     = string
      source_address_prefix      = string
      destination_address_prefix = optional(string, "*")
    }))
  }))
  description = "One entry per NSG. Each attaches to exactly one subnet, so a rule opened here cannot widen another subnet."

  validation {
    condition     = alltrue([for nsg in var.nsgs : alltrue([for rule in nsg.rules : rule.priority >= 100 && rule.priority <= 4096])])
    error_message = "NSG rule priorities must be between 100 and 4096."
  }

  validation {
    condition     = alltrue([for nsg in var.nsgs : length(distinct([for rule in nsg.rules : "${rule.direction}:${rule.priority}"])) == length(nsg.rules)])
    error_message = "Within one NSG each priority must be unique per direction; Azure rejects duplicates."
  }
}

variable "tags" {
  type        = map(string)
  description = "Tags applied to every NSG."
  default     = {}
}
