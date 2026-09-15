variable "name" {
  type        = string
  description = "Application Gateway name. WAF_v2 has a significant hourly cost."
}

variable "resource_group_name" {
  type        = string
  description = "Existing resource group name."
}

variable "location" {
  type        = string
  description = "Azure region."
}

variable "subnet_id" {
  type        = string
  description = "Dedicated Application Gateway subnet, /24 recommended."
}

variable "backend_hostnames" {
  type        = list(string)
  description = "Reachable HTTPS backend FQDNs with trusted certificates and a healthy / endpoint."
}

variable "listener_hostname" {
  type        = string
  description = "HTTPS hostname matching the supplied listener certificate. Configure DNS separately."
}

variable "certificate_base64" {
  type        = string
  description = "Base64-encoded PFX certificate including its private key. Stored in state; use Key Vault certificate references in production."
  sensitive   = true
}

variable "certificate_password" {
  type        = string
  description = "PFX password. Supply securely and never commit it."
  sensitive   = true
}

variable "tags" {
  type        = map(string)
  description = "Resource tags."
  default     = {}
}