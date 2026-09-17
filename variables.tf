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
      address_prefixes    = list(string)
      nat_gateway_enabled = optional(bool, false)
      nsg_rules = optional(map(object({
        priority                   = number
        direction                  = optional(string, "Inbound")
        access                     = optional(string, "Allow")
        protocol                   = optional(string, "Tcp")
        destination_port_range     = string
        source_address_prefix      = string
        destination_address_prefix = optional(string, "*")
      })), {})
    }))
  }))
  description = "Virtual networks keyed by short name. Every subnet gets its own NSG carrying only that subnet's nsg_rules, plus a NAT gateway when nat_gateway_enabled is set."
  default = {
    lb = {
      address_space = ["10.10.0.0/16"]
      subnets = {
        frontend = {
          address_prefixes = ["10.10.1.0/24"]
          nsg_rules = {
            deny_other_inbound = {
              priority               = 4096
              access                 = "Deny"
              protocol               = "*"
              destination_port_range = "*"
              source_address_prefix  = "*"
            }
          }
        }
      }
    }
    workload = {
      address_space = ["10.20.0.0/16"]
      subnets = {
        web = {
          address_prefixes    = ["10.20.1.0/24"]
          nat_gateway_enabled = true
          nsg_rules = {
            deny_other_inbound = {
              priority               = 4096
              access                 = "Deny"
              protocol               = "*"
              destination_port_range = "*"
              source_address_prefix  = "*"
            }
          }
        }
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

  validation {
    condition     = alltrue([for vnet in var.vnets : alltrue([for subnet in vnet.subnets : alltrue([for rule in subnet.nsg_rules : rule.priority >= 100 && rule.priority <= 4096])])])
    error_message = "NSG rule priorities must be between 100 and 4096."
  }

  validation {
    condition     = alltrue([for vnet in var.vnets : alltrue([for subnet in vnet.subnets : length(distinct([for rule in subnet.nsg_rules : "${rule.direction}:${rule.priority}"])) == length(subnet.nsg_rules)])])
    error_message = "Within one subnet's nsg_rules each priority must be unique per direction; Azure rejects duplicates."
  }

  validation {
    condition     = alltrue([for vnet in var.vnets : alltrue([for subnet in vnet.subnets : alltrue([for rule in subnet.nsg_rules : contains(["Inbound", "Outbound"], rule.direction) && contains(["Allow", "Deny"], rule.access)])])])
    error_message = "direction must be Inbound or Outbound, and access must be Allow or Deny."
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
    role              = optional(string, "web")
    size              = optional(string, "Standard_D2ls_v7")
    public_ip_enabled = optional(bool, true)
    domain_name_label = optional(string)
  }))
  description = "VMs keyed by short name. Role web runs Apache behind the load balancer; role jump is a plain host for reaching the others privately."
  default = {
    web1 = {
      vnet_key   = "workload"
      subnet_key = "web"
    }
    jump = {
      vnet_key   = "lb"
      subnet_key = "frontend"
      role       = "jump"
    }
  }

  validation {
    condition     = alltrue([for vm in var.vms : contains(["web", "jump"], vm.role)])
    error_message = "Each VM's role must be either web or jump."
  }

  validation {
    condition     = alltrue([for vm in var.vms : contains(keys(var.vnets), vm.vnet_key) && contains(keys(var.vnets[vm.vnet_key].subnets), vm.subnet_key)])
    error_message = "Each VM's vnet_key and subnet_key must name a network and subnet defined in var.vnets."
  }

  validation {
    condition     = length(distinct([for vm in var.vms : vm.vnet_key if vm.role == "web"])) <= 1
    error_message = "All web VMs must share one vnet_key; a Standard public load balancer cannot pool backends from more than one VNet."
  }
}

variable "admin_username" {
  type        = string
  description = "Local administrator username. Password login is disabled; only the generated key can log in."
  default     = "azureuser"
}

variable "http_port" {
  type        = number
  description = "Port Apache serves on and the load balancer listens and probes on. Changing it also means updating the matching port in nsg_rules. Plain HTTP; carry no credentials or real data."
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
