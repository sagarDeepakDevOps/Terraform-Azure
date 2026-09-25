variable "prefix" {
  type        = string
  description = "Prefixes every resource name. Must differ from the other labs' prefixes in this subscription."

  validation {
    condition     = can(regex("^[a-z][a-z0-9-]{1,18}[a-z0-9]$", var.prefix))
    error_message = "Use 3-20 lowercase letters, digits or hyphens, starting with a letter and ending alphanumeric."
  }
}

variable "location" {
  type        = string
  description = "Azure region for everything."
}

variable "admin_username" {
  type        = string
  description = "Login user on every VM. Password login is disabled; only the generated key works."
  default     = "azureuser"
}

variable "hub" {
  type = object({
    address_space = list(string)
    subnets = map(object({
      address_prefixes   = list(string)
      route_via_firewall = optional(bool, false)
      nsg_rules = optional(map(object({
        priority                     = number
        direction                    = optional(string, "Inbound")
        access                       = optional(string, "Allow")
        protocol                     = optional(string, "Tcp")
        source_address_prefixes      = list(string)
        destination_port_ranges      = optional(list(string), ["*"])
        destination_address_prefixes = optional(list(string), ["*"])
      })))
    }))
    firewall_sku_tier = optional(string, "Basic")
    bastion_sku       = optional(string, "Standard")
  })
  description = "The hub VNet. AzureFirewallSubnet, AzureFirewallManagementSubnet (Basic tier) and AzureBastionSubnet are fixed by Azure. Any other subnet with nsg_rules can hold VMs."
}

variable "spokes" {
  type = map(object({
    address_space = list(string)
    subnets = map(object({
      address_prefixes = list(string)
      nsg_rules = optional(map(object({
        priority                     = number
        direction                    = optional(string, "Inbound")
        access                       = optional(string, "Allow")
        protocol                     = optional(string, "Tcp")
        source_address_prefixes      = list(string)
        destination_port_ranges      = optional(list(string), ["*"])
        destination_address_prefixes = optional(list(string), ["*"])
      })), {})
    }))
  }))
  description = "Spoke VNets keyed by short name. Each gets its own NSGs, a default route to the firewall and a peering with the hub."

  validation {
    condition     = alltrue(flatten([for spoke in var.spokes : [for cidr in spoke.address_space : can(cidrnetmask(cidr))]]))
    error_message = "Every spoke address_space entry must be a valid IPv4 CIDR."
  }

  validation {
    condition     = !contains(keys(var.spokes), "hub")
    error_message = "No spoke may be called hub; that key means the hub VNet in vms and firewall_application_rules."
  }
}

variable "vms" {
  type = map(object({
    vnet_key           = string
    subnet_key         = string
    private_ip_address = optional(string)
    size               = optional(string, "Standard_D2ls_v7")
    install_apache     = optional(bool, false)
  }))
  description = "VMs keyed by hostname. vnet_key is hub or a spoke key. install_apache true serves a test page; otherwise it is a plain host. None has a public IP."

  validation {
    condition     = alltrue([for vm in var.vms : vm.vnet_key == "hub" ? try(var.hub.subnets[vm.subnet_key].nsg_rules != null, false) : try(contains(keys(var.spokes[vm.vnet_key].subnets), vm.subnet_key), false)])
    error_message = "Every VM's vnet_key and subnet_key must name a spoke subnet, or a hub subnet that has nsg_rules."
  }
}

variable "firewall_dnat_rules" {
  type = map(object({
    vm_key      = string
    port        = number
    public_port = optional(number)
  }))
  description = "Publish a VM port on the firewall's public IP. public_port defaults to port. The VM needs a static private_ip_address."
  default     = {}

  validation {
    condition     = alltrue([for rule in var.firewall_dnat_rules : try(var.vms[rule.vm_key].private_ip_address != null, false)])
    error_message = "Every vm_key must name a VM in vms that sets private_ip_address."
  }

  validation {
    condition     = length(distinct([for rule in var.firewall_dnat_rules : coalesce(rule.public_port, rule.port)])) == length(var.firewall_dnat_rules)
    error_message = "Two rules cannot publish on the same firewall port."
  }
}

variable "firewall_network_rules" {
  type = map(object({
    source_spokes      = list(string)
    destination_spokes = list(string)
    protocols          = list(string)
    destination_ports  = list(string)
  }))
  description = "Spoke-to-spoke allow rules, written with spoke keys instead of CIDRs. Traffic between spokes with no rule is dropped at the hub. Hub-to-spoke traffic goes over the peering and never reaches the firewall."
  default     = {}

  validation {
    condition     = alltrue([for rule in var.firewall_network_rules : alltrue([for spoke in concat(rule.source_spokes, rule.destination_spokes) : contains(keys(var.spokes), spoke)])])
    error_message = "Every source_spokes and destination_spokes entry must be a key of spokes."
  }

  validation {
    condition     = alltrue([for rule in var.firewall_network_rules : alltrue([for protocol in rule.protocols : contains(["TCP", "UDP", "ICMP", "Any"], protocol)])])
    error_message = "Network rule protocols must be TCP, UDP, ICMP or Any."
  }
}

variable "firewall_application_rules" {
  type = map(object({
    source_vnets      = list(string)
    destination_fqdns = list(string)
    protocols = optional(list(object({
      type = string
      port = number
      })), [
      { type = "Http", port = 80 },
      { type = "Https", port = 443 },
    ])
  }))
  description = "Outbound FQDN allow rules, written with hub or spoke keys. Anything a VM tries to reach on the Internet that is not listed here is denied."
  default     = {}

  validation {
    condition     = alltrue([for rule in var.firewall_application_rules : alltrue([for vnet in rule.source_vnets : vnet == "hub" || contains(keys(var.spokes), vnet)])])
    error_message = "Every source_vnets entry must be hub or a key of spokes."
  }
}

variable "tags" {
  type        = map(string)
  description = "Tags applied to every resource that takes them."
  default     = {}
}
