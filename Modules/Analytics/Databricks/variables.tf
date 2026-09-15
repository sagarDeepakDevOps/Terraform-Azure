variable "name" {
  type        = string
  description = "Databricks workspace name. This creates workspace infrastructure, not clusters, jobs or a Unity Catalog metastore."
}

variable "resource_group_name" {
  type        = string
  description = "Existing resource group name."
}

variable "location" {
  type        = string
  description = "Azure region."
}

variable "virtual_network_id" {
  type        = string
  description = "VNet for secure cluster connectivity with explicit NAT egress."
}

variable "public_subnet_name" {
  type        = string
  description = "Host subnet name delegated to Microsoft.Databricks/workspaces. Despite its Azure terminology, VMs have no public IPs."
}

variable "private_subnet_name" {
  type        = string
  description = "Container subnet name delegated to Microsoft.Databricks/workspaces."
}

variable "public_nsg_association_id" {
  type        = string
  description = "Host subnet NSG association ID, not the NSG ID."
}

variable "private_nsg_association_id" {
  type        = string
  description = "Container subnet NSG association ID."
}

variable "storage_account_id" {
  type        = string
  description = "Data lake ARM ID for the access connector grant. Configure a Unity Catalog storage credential separately."
}

variable "tags" {
  type        = map(string)
  description = "Resource tags."
  default     = {}
}