variable "first" {
  type = object({
    name                = string
    id                  = string
    resource_group_name = string
  })
  description = "First VNet, normally the hub."
}

variable "second" {
  type = object({
    name                = string
    id                  = string
    resource_group_name = string
  })
  description = "Second VNet, normally a spoke with non-overlapping address space."
}

variable "allow_forwarded_traffic" {
  type        = bool
  description = "Allow traffic forwarded by a network appliance. Peering is not transitive."
  default     = false
}

variable "use_first_gateway" {
  type        = bool
  description = "Enable gateway transit only after a gateway exists in the first VNet."
  default     = false
}