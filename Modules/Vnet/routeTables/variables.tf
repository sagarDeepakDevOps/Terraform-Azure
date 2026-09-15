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

variable "bgp_route_propagation_enabled" {
  type        = bool
  description = "Whether to propagate learned gateway routes."
  default     = true
}

variable "routes" {
  type = map(object({
    address_prefix         = string
    next_hop_type          = string
    next_hop_in_ip_address = optional(string)
  }))
  description = "User-defined routes keyed by name. VirtualAppliance routes need a reachable next-hop IP."
  default     = {}
}

variable "subnet_ids" {
  type        = map(string)
  description = "Workload subnets to associate; never blindly attach a default route to a gateway subnet."
  default     = {}
}

variable "tags" {
  type        = map(string)
  description = "Resource tags."
  default     = {}
}