variable "name" {
  type        = string
  description = "Route-based VPN gateway name."
}

variable "resource_group_name" {
  type        = string
  description = "Existing resource group name."
}

variable "location" {
  type        = string
  description = "Region supporting zone-redundant VPN Gateway."
}

variable "subnet_id" {
  type        = string
  description = "GatewaySubnet ID with a /27 or larger range and no NSG."
}

variable "on_premises" {
  type = object({
    gateway_address = string
    address_space   = list(string)
  })
  description = "Optional on-premises public VPN IP and routed CIDRs. The remote VPN device must be configured separately."
  default     = null
}

variable "shared_key" {
  type        = string
  description = "Site-to-site pre-shared key, supplied securely. Stored in state."
  sensitive   = true
  default     = null
  validation {
    condition     = var.on_premises == null || try(length(var.shared_key) >= 16, false)
    error_message = "Provide a shared key of at least 16 characters when creating a site-to-site connection."
  }
}

variable "tags" {
  type        = map(string)
  description = "Resource tags."
  default     = {}
}