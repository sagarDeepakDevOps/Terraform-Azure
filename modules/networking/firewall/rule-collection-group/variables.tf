variable "name" {
  type        = string
  description = "Rule collection group name, unique within the policy."
}

variable "firewall_policy_id" {
  type        = string
  description = "Firewall policy the group belongs to."
}

variable "priority" {
  type        = number
  description = "Group priority within the policy; lower is evaluated first among groups of the same rule type."
  default     = 100
}

variable "dnat_rules" {
  type = map(object({
    protocols           = list(string)
    source_addresses    = list(string)
    destination_address = string
    destination_ports   = list(string)
    translated_address  = string
    translated_port     = number
  }))
  description = "Inbound DNAT rules. destination_address is the firewall's own public IP."
  default     = {}
}

variable "network_rules" {
  type = map(object({
    protocols             = list(string)
    source_addresses      = list(string)
    destination_addresses = list(string)
    destination_ports     = list(string)
  }))
  description = "Layer-4 allow rules, used here for spoke-to-spoke traffic."
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
  description = "FQDN allow rules for outbound HTTP and HTTPS."
  default     = {}
}
