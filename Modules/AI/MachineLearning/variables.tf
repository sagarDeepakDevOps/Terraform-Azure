variable "name" {
  type        = string
  description = "Azure Machine Learning workspace name. No training cluster, notebook VM or model endpoint is provisioned."
}

variable "resource_group_name" {
  type        = string
  description = "Existing resource group name."
}

variable "location" {
  type        = string
  description = "Azure region."
}

variable "application_insights_id" {
  type        = string
  description = "Associated Application Insights ARM ID."
}

variable "key_vault_id" {
  type        = string
  description = "Associated Key Vault with roles granted to the workspace identity."
}

variable "storage_account_id" {
  type        = string
  description = "Standard non-HNS storage account with identity access and private connectivity."
}

variable "identity_id" {
  type        = string
  description = "Pre-authorized user-assigned workspace identity."
}

variable "tags" {
  type        = map(string)
  description = "Resource tags."
  default     = {}
}