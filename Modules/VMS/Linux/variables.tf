variable "vms" {
  type = map(object({
    subnet_id         = string
    size              = optional(string, "Standard_D2ls_v7")
    install_apache    = optional(bool, true)
    public_ip_enabled = optional(bool, true)
    domain_name_label = optional(string)
  }))
  description = "VMs keyed by short name; the key is appended to name_prefix to name the VM, NIC and public IP. install_apache false leaves a plain host such as a jump box."
}

variable "name_prefix" {
  type        = string
  description = "Prefix joined to each map key to build resource names."
}

variable "resource_group_name" {
  type        = string
  description = "Existing resource group name."
}

variable "location" {
  type        = string
  description = "Azure region."
}

variable "admin_username" {
  type        = string
  description = "Local administrator username. Password login is disabled; only the generated key can log in."
  default     = "azureuser"
}

variable "private_key_path" {
  type        = string
  description = "Where to write the one generated private key shared by every VM. Keep it out of version control."
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
