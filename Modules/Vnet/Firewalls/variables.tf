variable "name" {
  type        = string
  description = "Azure Firewall name. Standard Firewall has a significant hourly cost."
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
  description = "AzureFirewallSubnet ID with a /26 or larger range and no NSG."
}

variable "source_address_prefixes" {
  type        = list(string)
  description = "Workload CIDRs permitted to use the application egress rules."
}

variable "allowed_fqdns" {
  type        = list(string)
  description = "Allowed HTTP/HTTPS destinations. Other application traffic is denied."
  default     = ["*.ubuntu.com", "*.debian.org", "packages.microsoft.com"]
}

variable "tags" {
  type        = map(string)
  description = "Resource tags."
  default     = {}
}