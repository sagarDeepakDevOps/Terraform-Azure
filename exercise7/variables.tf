variable "resource_group_name" {
  type        = string
  description = "Resource group from exercise1."
}

variable "prefix" {
  type        = string
  description = "Same prefix used in exercise1."
}

variable "vms" {
  type = map(object({
    vnet_key          = string
    subnet_name       = string
    role              = optional(string, "web")
    size              = optional(string, "Standard_D2ls_v7")
    public_ip_enabled = optional(bool, true)
  }))
  description = "VMs keyed by short name. Role web installs Apache and is what exercise8 load balances; role jump is a plain host you SSH into."

  validation {
    condition     = alltrue([for vm in var.vms : contains(["web", "jump"], vm.role)])
    error_message = "Each VM's role must be either web or jump."
  }

  validation {
    condition     = length(distinct([for vm in var.vms : vm.vnet_key if vm.role == "web"])) <= 1
    error_message = "All web VMs must share one vnet_key; a Standard public load balancer cannot pool backends from more than one VNet."
  }
}

variable "admin_username" {
  type        = string
  description = "Login user on every VM. Password login is disabled; only the generated key works."
  default     = "azureuser"
}

variable "lb_public_ip" {
  type        = string
  description = "Leave null on the first run: exercise8 has not created the load balancer yet. After exercise8, set it and re-apply so the demo page names the load balancer. Changing it replaces the web VMs, because it is baked into cloud-init."
  default     = null
}

variable "tags" {
  type        = map(string)
  description = "Tags applied to every VM."
  default     = {}
}
