variable "prefix" {
  type        = string
  description = "Short lowercase naming prefix."
  default     = "aztfedge"
}

variable "location" {
  type        = string
  description = "Region for regional resources; Front Door and Traffic Manager are global."
  default     = "eastus2"
}

variable "dns_zone_name" {
  type        = string
  description = "Demonstration DNS zone. Replace with an owned domain and delegate it for real DNS use."
  default     = "terraform-demo.example"
}

variable "enable_application_gateway" {
  type        = bool
  description = "Deploy an independent HTTPS WAF_v2 gateway; requires a certificate and reachable backend."
  default     = false
}

variable "gateway_backend_hostnames" {
  type        = list(string)
  description = "Existing HTTPS backends for the independent gateway, not the Front-Door-restricted web origin."
  default     = []
  validation {
    condition     = !var.enable_application_gateway || length(var.gateway_backend_hostnames) > 0
    error_message = "Provide reachable HTTPS backend hostnames before enabling Application Gateway."
  }
}

variable "gateway_listener_hostname" {
  type        = string
  description = "Hostname present in the gateway listener PFX certificate."
  default     = null
  validation {
    condition     = !var.enable_application_gateway || var.gateway_listener_hostname != null
    error_message = "Supply the gateway certificate hostname when enabling Application Gateway."
  }
}

variable "gateway_certificate_base64" {
  type        = string
  description = "Base64 PFX supplied securely through TF_VAR_gateway_certificate_base64."
  default     = null
  sensitive   = true
  validation {
    condition     = !var.enable_application_gateway || var.gateway_certificate_base64 != null
    error_message = "Supply a PFX certificate before enabling the HTTPS gateway."
  }
}

variable "gateway_certificate_password" {
  type        = string
  description = "PFX password supplied securely. An empty string is allowed only for a passwordless PFX."
  default     = null
  sensitive   = true
  validation {
    condition     = !var.enable_application_gateway || var.gateway_certificate_password != null
    error_message = "Supply the PFX password when enabling Application Gateway."
  }
}

variable "traffic_manager_endpoints" {
  type = map(object({
    hostname = string
    priority = number
  }))
  description = "Empty disables Traffic Manager; provide at least two independent HTTPS endpoints to enable it."
  default     = {}
}

variable "tags" {
  type        = map(string)
  description = "Common resource tags."
  default     = { environment = "demo", project = "terraform-azure", managed_by = "terraform" }
}