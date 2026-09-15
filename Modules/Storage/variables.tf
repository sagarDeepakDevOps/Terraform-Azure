variable "name" {
  type        = string
  description = "Globally unique storage account name, 3-24 lowercase letters or digits."
  validation {
    condition     = can(regex("^[a-z0-9]{3,24}$", var.name))
    error_message = "Storage names must contain 3-24 lowercase letters or digits."
  }
}

variable "resource_group_name" {
  type        = string
  description = "Existing resource group name."
}

variable "location" {
  type        = string
  description = "Azure region."
}

variable "replication_type" {
  type        = string
  description = "Storage replication SKU; LRS is a demo cost choice, not a production availability recommendation."
  default     = "LRS"
}

variable "public_network_access_enabled" {
  type        = bool
  description = "Enable only for explicitly allowed public runner IPs or supported trusted services."
  default     = false
}

variable "allowed_ip_addresses" {
  type        = list(string)
  description = "Public IPv4 addresses/CIDRs allowed by the firewall when public access is enabled."
  default     = []
}

variable "hierarchical_namespace_enabled" {
  type        = bool
  description = "Enable ADLS Gen2. Blob versioning is disabled when HNS is enabled."
  default     = false
}

variable "containers" {
  type        = set(string)
  description = "Private blob containers, also ADLS filesystems when HNS is enabled."
  default     = ["data"]
}

variable "file_shares" {
  type        = map(number)
  description = "SMB share names and quotas in GiB. Configure SMB identity authentication separately before mounting."
  default     = {}
}

variable "queues" {
  type        = set(string)
  description = "Storage queue names."
  default     = []
}

variable "tables" {
  type        = set(string)
  description = "Alphanumeric table names created through ARM using AzAPI, without enabling shared keys."
  default     = []
}

variable "enable_lifecycle_policy" {
  type        = bool
  description = "Demonstrate tiering and deletion for blobs under data/. Review retention requirements first."
  default     = false
}

variable "tags" {
  type        = map(string)
  description = "Resource tags."
  default     = {}
}