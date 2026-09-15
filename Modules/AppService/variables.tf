variable "name" {
  type        = string
  description = "Globally unique Linux Web App name. This creates hosting; deploy application code separately."
}

variable "resource_group_name" {
  type        = string
  description = "Existing resource group name."
}

variable "location" {
  type        = string
  description = "Azure region."
}

variable "sku_name" {
  type        = string
  description = "App Service plan SKU supporting Always On and VNet integration."
  default     = "B1"
}

variable "integration_subnet_id" {
  type        = string
  description = "Optional subnet delegated to Microsoft.Web/serverFarms; VNet integration is outbound, not private inbound access."
  default     = null
}

variable "app_settings" {
  type        = map(string)
  description = "Application settings. Use Key Vault references for secrets; settings are still stored in state."
  default     = {}
  sensitive   = true
}

variable "front_door_only" {
  type        = bool
  description = "Restrict incoming application requests to one Front Door instance."
  default     = false
}

variable "front_door_id" {
  type        = string
  description = "Front Door profile resource_guid for X-Azure-FDID filtering, not its ARM ID."
  default     = null
  validation {
    condition     = !var.front_door_only || var.front_door_id != null
    error_message = "Supply the Front Door resource GUID when enabling origin restrictions."
  }
}

variable "tags" {
  type        = map(string)
  description = "Resource tags."
  default     = {}
}