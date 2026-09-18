variable "prefix" {
  type        = string
  description = "Prefixes every resource name. Must differ from the prefix the numbered exercises use, or the two configurations fight over the same resources."

  validation {
    condition     = can(regex("^[a-z][a-z0-9-]{1,22}[a-z0-9]$", var.prefix))
    error_message = "Use 3-24 lowercase letters, digits or hyphens, starting with a letter and ending alphanumeric."
  }
}

variable "location" {
  type        = string
  description = "Azure region. Set once here; every resource inherits it from the resource group."
}

variable "vnets" {
  type = map(object({
    address_space = list(string)
  }))
  description = "Virtual networks keyed by short name. Ranges must not overlap, or the peering is rejected."

  validation {
    condition     = alltrue([for vnet in var.vnets : alltrue([for cidr in vnet.address_space : can(cidrnetmask(cidr))])])
    error_message = "Every address_space entry must be a valid IPv4 CIDR."
  }
}

variable "vnet_subnets" {
  type = map(map(object({
    address_prefixes = list(string)
  })))
  description = "Subnets grouped by the VNet short name they belong to. Each inner key becomes the Azure subnet name."

  validation {
    condition     = alltrue([for subnets in var.vnet_subnets : alltrue([for subnet in subnets : alltrue([for cidr in subnet.address_prefixes : can(cidrnetmask(cidr))])])])
    error_message = "Every address_prefixes entry must be a valid IPv4 CIDR, and must fit inside its VNet address space."
  }

  validation {
    condition     = alltrue([for key in keys(var.vnet_subnets) : contains(keys(var.vnets), key)])
    error_message = "Every key in vnet_subnets must name a VNet declared in vnets."
  }
}

variable "nsgs" {
  type = map(object({
    vnet_key    = string
    subnet_name = string
    rules = map(object({
      priority                   = number
      direction                  = optional(string, "Inbound")
      access                     = optional(string, "Allow")
      protocol                   = optional(string, "Tcp")
      destination_port_range     = string
      source_address_prefix      = string
      destination_address_prefix = optional(string, "*")
    }))
  }))
  description = "One entry per NSG. Each attaches to exactly one subnet, so a rule opened here cannot widen another subnet."

  validation {
    condition     = alltrue([for nsg in var.nsgs : alltrue([for rule in nsg.rules : rule.priority >= 100 && rule.priority <= 4096])])
    error_message = "NSG rule priorities must be between 100 and 4096."
  }

  validation {
    condition     = alltrue([for nsg in var.nsgs : length(distinct([for rule in nsg.rules : "${rule.direction}:${rule.priority}"])) == length(nsg.rules)])
    error_message = "Within one NSG each priority must be unique per direction; Azure rejects duplicates."
  }

  validation {
    condition     = alltrue([for nsg in var.nsgs : try(contains(keys(var.vnet_subnets[nsg.vnet_key]), nsg.subnet_name), false)])
    error_message = "Every NSG's vnet_key and subnet_name must name a subnet declared in vnet_subnets."
  }
}

variable "vnet_peerings" {
  type = map(object({
    first  = string
    second = string
  }))
  description = "Bidirectional peerings keyed by name. first and second are VNet short names, and their address spaces must not overlap."
  default     = {}

  validation {
    condition     = alltrue([for peering in var.vnet_peerings : contains(keys(var.vnets), peering.first) && contains(keys(var.vnets), peering.second) && peering.first != peering.second])
    error_message = "Each peering must name two different VNets declared in vnets."
  }
}

variable "nat_gateways" {
  type = map(object({
    vnet_key    = string
    subnet_name = string
  }))
  description = "Subnets that need outbound Internet without public IPs on their VMs. Each gateway consumes one public IP and is billable."
  default     = {}

  validation {
    condition     = alltrue([for nat in var.nat_gateways : try(contains(keys(var.vnet_subnets[nat.vnet_key]), nat.subnet_name), false)])
    error_message = "Every NAT gateway's vnet_key and subnet_name must name a subnet declared in vnet_subnets."
  }
}

variable "vms" {
  type = map(object({
    vnet_key          = string
    subnet_name       = string
    role              = optional(string, "web")
    size              = optional(string, "Standard_D2ls_v7")
    public_ip_enabled = optional(bool, true)
  }))
  description = "VMs keyed by short name. Role web installs Apache and goes into the load balancer's backend pool; role jump is a plain host you SSH into."

  validation {
    condition     = alltrue([for vm in var.vms : contains(["web", "jump"], vm.role)])
    error_message = "Each VM's role must be either web or jump."
  }

  validation {
    condition     = length(distinct([for vm in var.vms : vm.vnet_key if vm.role == "web"])) <= 1
    error_message = "All web VMs must share one vnet_key; a Standard public load balancer cannot pool backends from more than one VNet."
  }

  validation {
    condition     = alltrue([for vm in var.vms : try(contains(keys(var.vnet_subnets[vm.vnet_key]), vm.subnet_name), false)])
    error_message = "Every VM's vnet_key and subnet_name must name a subnet declared in vnet_subnets."
  }
}

variable "admin_username" {
  type        = string
  description = "Login user on every VM. Password login is disabled; only the generated key works."
  default     = "azureuser"
}

variable "http_port" {
  type        = number
  description = "Port the load balancer listens and probes on, and the port Apache serves. A rule in the web subnet's NSG must allow it."
  default     = 80
}

variable "lb_domain_name_label" {
  type        = string
  description = "Optional DNS label giving <label>.<region>.cloudapp.azure.com. Must be unique across the whole region, so an apply fails if it is taken. Null means clients use the frontend IP."
  default     = null
}

variable "tags" {
  type        = map(string)
  description = "Tags applied to every resource that takes them."
  default     = {}
}
