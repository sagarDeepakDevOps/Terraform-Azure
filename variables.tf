# Map-driven inputs: keys name resources and join VMs to subnets, so treat them as stable identifiers.

variable "prefix" {
  type        = string
  description = "3-24 lowercase letters, digits or hyphens, starting with a letter and ending alphanumeric; prefixes every resource name."
  default     = "apachelab"

  validation {
    condition     = can(regex("^[a-z][a-z0-9-]{1,22}[a-z0-9]$", var.prefix))
    error_message = "Use 3-24 lowercase letters, digits or hyphens, starting with a letter and ending with a letter or digit."
  }
}

variable "location" {
  type        = string
  description = "Azure region for every resource, and the region public DNS labels are scoped to."
  default     = "eastus2"
}

variable "vnets" {
  type = map(object({
    address_space = list(string)
    subnets = map(object({
      address_prefixes = list(string)
    }))
  }))
  description = "Virtual networks keyed by short name. Each key names one network and one NSG; subnet keys become Azure subnet names."
  default = {
    lb = {
      address_space = ["10.10.0.0/16"]
      subnets = {
        frontend = { address_prefixes = ["10.10.1.0/24"] }
      }
    }
    workload = {
      address_space = ["10.20.0.0/16"]
      subnets = {
        web = { address_prefixes = ["10.20.1.0/24"] }
      }
    }
  }

  validation {
    condition     = alltrue([for vnet in var.vnets : alltrue([for cidr in vnet.address_space : can(cidrnetmask(cidr))])])
    error_message = "Every VNet address_space entry must be a valid IPv4 CIDR."
  }

  validation {
    condition     = alltrue([for vnet in var.vnets : alltrue([for subnet in vnet.subnets : alltrue([for cidr in subnet.address_prefixes : can(cidrnetmask(cidr))])])])
    error_message = "Every subnet address_prefixes entry must be a valid IPv4 CIDR."
  }
}

variable "vnet_peerings" {
  type = map(object({
    first  = string
    second = string
  }))
  description = "Bidirectional peerings keyed by name; first and second are keys of var.vnets with non-overlapping address space."
  default = {
    lb_to_workload = {
      first  = "lb"
      second = "workload"
    }
  }

  validation {
    condition     = alltrue([for peering in var.vnet_peerings : contains(keys(var.vnets), peering.first) && contains(keys(var.vnets), peering.second)])
    error_message = "Each peering's first and second must name a key that exists in var.vnets."
  }
}

variable "vms" {
  type = map(object({
    vnet_key          = string
    subnet_key        = string
    size              = optional(string, "Standard_B1s")
    domain_name_label = optional(string)
  }))
  description = "Apache web servers keyed by short name. A public load balancer pool takes its network from its NICs, so all VMs must share one vnet_key."
  default = {
    web1 = {
      vnet_key   = "workload"
      subnet_key = "web"
    }
    web2 = {
      vnet_key   = "workload"
      subnet_key = "web"
    }
  }

  validation {
    condition     = alltrue([for vm in var.vms : contains(keys(var.vnets), vm.vnet_key) && contains(keys(var.vnets[vm.vnet_key].subnets), vm.subnet_key)])
    error_message = "Each VM's vnet_key and subnet_key must name a network and subnet defined in var.vnets."
  }

  validation {
    condition     = length(distinct([for vm in var.vms : vm.vnet_key])) <= 1
    error_message = "All VMs must share one vnet_key; a Standard public load balancer cannot pool backends from more than one VNet."
  }
}

variable "admin_username" {
  type        = string
  description = "Local administrator username. Password login is disabled; only the generated key can log in."
  default     = "azureuser"
}

variable "ssh_source_address_prefix" {
  type        = string
  description = "Source CIDR or IP allowed to reach port 22. Null leaves SSH closed; avoid \"*\"."
  default     = null
}

variable "http_port" {
  type        = number
  description = "Port Apache serves on and the load balancer listens and probes on. Plain HTTP; carry no credentials or real data."
  default     = 80
}

variable "lb_domain_name_label" {
  type        = string
  description = "Optional DNS label giving the load balancer <label>.<region>.cloudapp.azure.com. Must be unique across the whole region."
  default     = null
}

variable "tags" {
  type        = map(string)
  description = "Tags applied to every taggable resource."
  default = {
    environment = "lab"
    project     = "terraform-azure"
    example     = "apache-behind-lb"
    managed_by  = "terraform"
  }
}
