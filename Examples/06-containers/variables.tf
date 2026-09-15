variable "prefix" {
  type        = string
  description = "Short lowercase resource naming prefix."
  default     = "aztfctr"
  validation {
    condition     = can(regex("^[a-z][a-z0-9]{2,7}$", var.prefix))
    error_message = "Use 3-8 lowercase letters/digits, starting with a letter."
  }
}

variable "location" {
  type        = string
  description = "Azure region."
  default     = "eastus2"
}

variable "enable_aks" {
  type        = bool
  description = "Add private AKS with paid VM nodes."
  default     = false
}

variable "aks_admin_group_object_ids" {
  type        = list(string)
  description = "Existing Entra admin group object IDs; required when AKS is enabled."
  default     = []
  validation {
    condition     = !var.enable_aks || length(var.aks_admin_group_object_ids) > 0
    error_message = "Provide at least one existing Entra admin group when enabling AKS."
  }
}

variable "tags" {
  type        = map(string)
  description = "Common resource tags."
  default     = { environment = "demo", project = "terraform-azure", managed_by = "terraform" }
}