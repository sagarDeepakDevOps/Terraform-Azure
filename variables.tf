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
      address_prefixes = list(string)
    }))
    firewall_sku_tier = optional(string, "Basic")
    bastion_sku       = optional(string, "Standard")
  })
  description = "The hub VNet. Subnet names are fixed by Azure: AzureFirewallSubnet, AzureFirewallManagementSubnet (Basic tier) and AzureBastionSubnet."
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
}

variable "vms" {
  type = map(object({
    spoke_key          = string
    subnet_key         = string
    private_ip_address = optional(string)
    size               = optional(string, "Standard_D2ls_v7")
    install_apache     = optional(bool, true)
  }))
  description = "VMs keyed by hostname. None has a public IP; reach them through the firewall's DNAT or through Bastion."

  validation {
    condition     = alltrue([for vm in var.vms : try(contains(keys(var.spokes[vm.spoke_key].subnets), vm.subnet_key), false)])
    error_message = "Every VM's spoke_key and subnet_key must name a subnet declared in spokes."
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
  description = "Spoke-to-spoke allow rules, written with spoke keys instead of CIDRs. Traffic between spokes with no rule is dropped at the hub."
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
    source_spokes     = list(string)
    destination_fqdns = list(string)
    protocols = optional(list(object({
      type = string
      port = number
      })), [
      { type = "Http", port = 80 },
      { type = "Https", port = 443 },
    ])
  }))
  description = "Outbound FQDN allow rules, written with spoke keys. Anything a spoke tries to reach that is not listed here is denied."
  default     = {}

  validation {
    condition     = alltrue([for rule in var.firewall_application_rules : alltrue([for spoke in rule.source_spokes : contains(keys(var.spokes), spoke)])])
    error_message = "Every source_spokes entry must be a key of spokes."
  }
}

variable "tags" {
  type        = map(string)
  description = "Tags applied to every resource that takes them."
  default     = {}
}
