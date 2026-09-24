variable "prefix" {
  type        = string
  description = "Same prefix as the rest of the lab. Names the state resource group, and seeds the generated storage account name."

  validation {
    condition     = can(regex("^[a-z][a-z0-9-]{1,22}[a-z0-9]$", var.prefix))
    error_message = "Use 3-24 lowercase letters, digits or hyphens, starting with a letter and ending alphanumeric."
  }
}

variable "location" {
  type        = string
  description = "Azure region for the state resource group and storage account. It does not have to match the region the lab deploys into."
}

variable "storage_account_name" {
  type        = string
  description = "Exact storage account name. Leave null to generate one from the prefix plus a random tail, which is what keeps it globally unique."
  default     = null
}

variable "container_name" {
  type        = string
  description = "Blob container holding one state blob per configuration."
  default     = "tfstate"
}

variable "replication_type" {
  type        = string
  description = "Redundancy for the state account. LRS is the cheapest and is enough for a lab."
  default     = "LRS"
}

variable "retention_days" {
  type        = number
  description = "How long a deleted state blob stays recoverable."
  default     = 7
}

variable "shared_access_key_enabled" {
  type        = bool
  description = "Leave true unless you also set grant_current_user_blob_access. With both false the backend has no way to authenticate."
  default     = true
}

variable "grant_current_user_blob_access" {
  type        = bool
  description = "Grant the identity running this apply Storage Blob Data Contributor on the container, so backends can set use_azuread_auth. Needs Owner or User Access Administrator on the subscription."
  default     = false
}

variable "allowed_ip_ranges" {
  type        = list(string)
  description = "Public addresses allowed to reach the account, as bare addresses rather than /32. Empty means no firewall, which is the right default while you are learning."
  default     = []
}

variable "enable_delete_lock" {
  type        = bool
  description = "Protect the account with a CanNotDelete lock. Set it back to false and apply before you ever destroy this exercise."
  default     = false
}

variable "write_backend_config_file" {
  type        = bool
  description = "Write backend.hcl into full-lab so it can run terraform init -backend-config=backend.hcl. It holds names only, no keys."
  default     = true
}

variable "tags" {
  type        = map(string)
  description = "Tags applied to the state resource group and storage account."
  default     = {}
}
