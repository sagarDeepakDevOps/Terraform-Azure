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
    priority                     = number
    direction                    = optional(string, "Inbound")
    access                       = optional(string, "Allow")
    protocol                     = optional(string, "Tcp")
    source_address_prefixes      = list(string)
    destination_port_ranges      = optional(list(string), ["*"])
    destination_address_prefixes = optional(list(string), ["*"])
  }))
  description = "Rules keyed by name. A one-item source list may be a service tag such as AzureLoadBalancer; longer lists must be CIDRs."
  default     = {}

  validation {
    condition     = alltrue([for rule in var.rules : rule.priority >= 100 && rule.priority <= 4096])
    error_message = "Rule priorities must be between 100 and 4096."
  }

  validation {
    condition     = length(distinct([for rule in var.rules : "${rule.direction}:${rule.priority}"])) == length(var.rules)
    error_message = "Each priority must be unique per direction; Azure rejects duplicates."
  }

  validation {
    condition     = alltrue([for rule in var.rules : contains(["Tcp", "Udp", "Icmp", "Esp", "Ah", "*"], rule.protocol)])
    error_message = "protocol must be one of Tcp, Udp, Icmp, Esp, Ah or *."
  }
}

variable "subnet_ids" {
  type        = map(string)
  description = "Subnets to attach this NSG to, keyed by a name known at plan time."
  default     = {}
}

variable "tags" {
  type        = map(string)
  description = "Resource tags."
  default     = {}
}
