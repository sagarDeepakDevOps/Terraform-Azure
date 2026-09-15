variable "prefix" {
  type        = string
  description = "Short lowercase naming prefix."
  default     = "aztfana"
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

variable "enable_synapse" {
  type        = bool
  description = "Create a private Synapse workspace with serverless endpoints, without dedicated compute pools."
  default     = false
}

variable "enable_databricks" {
  type        = bool
  description = "Create a VNet-injected Databricks workspace and NAT egress, without clusters."
  default     = false
}

variable "configure_synapse_managed_endpoints" {
  type        = bool
  description = "Second-stage data-plane configuration. Enable only after Synapse exists and the runner can reach its private Dev endpoint."
  default     = false
  validation {
    condition     = !var.configure_synapse_managed_endpoints || var.enable_synapse
    error_message = "Enable the Synapse workspace before configuring its managed private endpoints."
  }
}

variable "tags" {
  type        = map(string)
  description = "Common resource tags."
  default     = { environment = "demo", project = "terraform-azure", managed_by = "terraform" }
}