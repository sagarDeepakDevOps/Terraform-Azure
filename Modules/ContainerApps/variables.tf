variable "name" {
  type        = string
  description = "Container App name."
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
  description = "Dedicated /27 or larger workload-profile subnet delegated to Microsoft.App/environments."
}

variable "log_analytics_workspace_id" {
  type        = string
  description = "Log Analytics workspace ARM ID."
}

variable "identity_id" {
  type        = string
  description = "User-assigned identity with AcrPull on the configured registry."
}

variable "registry_server" {
  type        = string
  description = "ACR login server for later private image deployments."
}

variable "image" {
  type        = string
  description = "Runnable image. Pin an immutable digest for production. The default public image demonstrates a working HTTP service."
  default     = "mcr.microsoft.com/azuredocs/containerapps-helloworld:latest"
}

variable "target_port" {
  type        = number
  description = "Container HTTP listening port."
  default     = 80
}

variable "tags" {
  type        = map(string)
  description = "Resource tags."
  default     = {}
}