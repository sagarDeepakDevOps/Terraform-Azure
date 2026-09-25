variable "name" {
  type        = string
  description = "Route table name."
}

variable "resource_group_name" {
  type        = string
  description = "Existing resource group name."
}

variable "location" {
  type        = string
  description = "Azure region."
}

variable "routes" {
  type = map(object({
    address_prefix         = string
    next_hop_type          = string
    next_hop_in_ip_address = optional(string)
  }))
  description = "User-defined routes keyed by name. The most specific prefix wins, and a UDR beats a system route of equal length."

  validation {
    condition     = alltrue([for route in var.routes : contains(["VirtualAppliance", "Internet", "VnetLocal", "VirtualNetworkGateway", "None"], route.next_hop_type)])
    error_message = "next_hop_type must be VirtualAppliance, Internet, VnetLocal, VirtualNetworkGateway or None."
  }

  validation {
    condition     = alltrue([for route in var.routes : route.next_hop_type != "VirtualAppliance" || route.next_hop_in_ip_address != null])
    error_message = "VirtualAppliance routes need next_hop_in_ip_address."
  }
}

variable "subnet_ids" {
  type        = map(string)
  description = "Subnets to attach this route table to, keyed by a name known at plan time."
  default     = {}
}

variable "bgp_route_propagation_enabled" {
  type        = bool
  description = "Whether gateway-learned routes are added to the subnets. Keep false in spokes that must egress through a firewall."
  default     = false
}

variable "tags" {
  type        = map(string)
  description = "Resource tags."
  default     = {}
}
