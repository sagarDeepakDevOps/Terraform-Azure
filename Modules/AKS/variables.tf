variable "name" {
  type        = string
  description = "Private AKS cluster name."
}

variable "resource_group_name" {
  type        = string
  description = "Existing resource group name."
}

variable "location" {
  type        = string
  description = "Azure region."
}

variable "kubernetes_version" {
  type        = string
  description = "Supported regional Kubernetes version. Null uses Azure's current default; choose explicitly for production."
  default     = null
}

variable "node_size" {
  type        = string
  description = "System node size; AKS system pools do not support B-series."
  default     = "Standard_D2s_v5"
}

variable "subnet_id" {
  type        = string
  description = "Non-delegated node subnet with a user-assigned NAT Gateway."
}

variable "identity_id" {
  type        = string
  description = "User-assigned control-plane identity with Network Contributor on the VNet, including private DNS VNet linking."
}

variable "identity_principal_id" {
  type        = string
  description = "Control-plane identity object ID, granted Managed Identity Operator on the explicit kubelet identity."
}

variable "tenant_id" {
  type        = string
  description = "Microsoft Entra tenant ID."
}

variable "admin_group_object_ids" {
  type        = list(string)
  description = "Existing Entra administrator group object IDs."
  validation {
    condition     = length(var.admin_group_object_ids) > 0
    error_message = "Provide at least one Entra administrator group for this private, local-account-disabled cluster."
  }
}

variable "log_analytics_workspace_id" {
  type        = string
  description = "Log Analytics workspace ARM ID."
}

variable "registry_id" {
  type        = string
  description = "ACR resource ID to grant the kubelet identity AcrPull."
}

variable "tags" {
  type        = map(string)
  description = "Resource tags."
  default     = {}
}