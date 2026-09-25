variable "resource_group_name" {
  type        = string
  description = "Existing resource group. Keep it separate from anything you routinely destroy."
}

variable "location" {
  type        = string
  description = "Azure region. It does not have to match the region the infrastructure deploys into."
}

variable "name_prefix" {
  type        = string
  description = "Seeds the generated account name; hyphens and other symbols are stripped."
}

variable "storage_account_name" {
  type        = string
  description = "Exact account name; null generates one from name_prefix plus 6 random characters."
  default     = null

  validation {
    condition     = var.storage_account_name == null || can(regex("^[a-z0-9]{3,24}$", var.storage_account_name))
    error_message = "Storage account names are 3-24 lowercase letters or digits."
  }
}

variable "container_name" {
  type        = string
  description = "Blob container holding one state blob per configuration."
  default     = "tfstate"
}

variable "replication_type" {
  type        = string
  description = "LRS is the cheapest and enough for a lab; use ZRS or GRS for state you cannot lose."
  default     = "LRS"

  validation {
    condition     = contains(["LRS", "ZRS", "GRS", "RAGRS", "GZRS", "RAGZRS"], var.replication_type)
    error_message = "replication_type must be LRS, ZRS, GRS, RAGRS, GZRS or RAGZRS."
  }
}

variable "retention_days" {
  type        = number
  description = "Days a deleted state blob or container stays recoverable."
  default     = 7

  validation {
    condition     = var.retention_days >= 1 && var.retention_days <= 365
    error_message = "retention_days must be between 1 and 365."
  }
}

variable "shared_access_key_enabled" {
  type        = bool
  description = "True lets the backend authenticate with the account key. False removes keys, so grant_current_user_blob_access must be true."
  default     = true
}

variable "grant_current_user_blob_access" {
  type        = bool
  description = "Grant the identity running this apply Storage Blob Data Contributor on the container, for use_azuread_auth = true. Needs Owner or User Access Administrator."
  default     = false

  validation {
    condition     = var.shared_access_key_enabled || var.grant_current_user_blob_access
    error_message = "With shared_access_key_enabled false the backend needs grant_current_user_blob_access true, or it has no way to sign in."
  }
}

variable "allowed_ip_ranges" {
  type        = list(string)
  description = "Public addresses allowed to reach the account, as bare IPs without /32. Empty means no firewall."
  default     = []
}

variable "enable_delete_lock" {
  type        = bool
  description = "Add a CanNotDelete lock. Set it back to false and apply before destroying."
  default     = false
}

variable "tags" {
  type        = map(string)
  description = "Resource tags."
  default     = {}
}
