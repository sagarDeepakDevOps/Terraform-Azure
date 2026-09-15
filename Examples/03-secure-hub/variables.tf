variable "prefix" {
  type        = string
  description = "Resource naming prefix."
  default     = "aztfhub"
}

variable "location" {
  type        = string
  description = "Azure region supporting the selected gateway SKUs."
  default     = "eastus2"
}

variable "enable_bastion" {
  type        = bool
  description = "Create paid Standard Bastion."
  default     = false
}

variable "enable_vpn" {
  type        = bool
  description = "Create a paid zone-redundant VPN Gateway and enable hub gateway transit."
  default     = false
}

variable "on_premises" {
  type = object({
    gateway_address = string
    address_space   = list(string)
  })
  description = "Optional real remote gateway details. Requires enable_vpn."
  default     = null
  validation {
    condition     = var.on_premises == null || var.enable_vpn
    error_message = "Enable the VPN gateway before supplying an on-premises connection."
  }
}

variable "vpn_shared_key" {
  type        = string
  description = "Supply securely when defining on_premises. Never commit the key."
  sensitive   = true
  default     = null
}

variable "tags" {
  type        = map(string)
  description = "Common resource tags."
  default     = { environment = "demo", project = "terraform-azure", managed_by = "terraform" }
}