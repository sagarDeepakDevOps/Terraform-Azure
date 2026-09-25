variable "hub" {
  type = object({
    name                = string
    id                  = string
    resource_group_name = string
  })
  description = "The hub VNet."
}

variable "spoke" {
  type = object({
    name                = string
    id                  = string
    resource_group_name = string
  })
  description = "The spoke VNet. Its address space must not overlap the hub's."
}

variable "use_hub_gateway" {
  type        = bool
  description = "Let the spoke use the hub's VPN or ExpressRoute gateway. Only set true once that gateway exists, or Azure rejects the peering."
  default     = false
}
