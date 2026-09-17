variable "name" {
  type        = string
  description = "Linux VM name; also prefixes the NIC and public IP names."
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
  description = "Subnet for the NIC. Its NSG must allow the inbound ports this VM serves."
}

variable "size" {
  type        = string
  description = "VM size; availability is per subscription and region, so confirm with az vm list-skus before changing."
  default     = "Standard_D2ls_v7"
}

variable "admin_username" {
  type        = string
  description = "Local administrator username."
  default     = "azureuser"
}

variable "public_ip_enabled" {
  type        = bool
  description = "Create an instance-level public IP. It exposes the VM to the Internet and is also the VM's outbound path for cloud-init package installs."
  default     = true
}

variable "domain_name_label" {
  type        = string
  description = "Optional DNS label for the VM public IP. Must be unique across the whole region, so an apply fails if another subscription already took it."
  default     = null
}

variable "lb_fqdn" {
  type        = string
  description = "Load balancer frontend DNS name used as the second virtual host's ServerName. Null when the frontend has no DNS label."
  default     = null
}

variable "lb_public_ip" {
  type        = string
  description = "Load balancer frontend IPv4 address, shown on the page served to load-balanced requests."
  default     = null
}

variable "tags" {
  type        = map(string)
  description = "Resource tags."
  default     = {}
}
