locals {
  # Firewall rules name spokes; the CIDRs are looked up here so they are written only once, in spokes.
  firewall_network_rules = {
    for name, rule in var.firewall_network_rules : name => {
      protocols             = rule.protocols
      source_addresses      = flatten([for spoke in rule.source_spokes : var.spokes[spoke].address_space])
      destination_addresses = flatten([for spoke in rule.destination_spokes : var.spokes[spoke].address_space])
      destination_ports     = rule.destination_ports
    }
  }

  # The key hub resolves to the hub's own range, so hub VMs can be given Internet egress too.
  vnet_address_spaces = merge({ hub = var.hub.address_space }, { for key, spoke in var.spokes : key => spoke.address_space })

  firewall_application_rules = {
    for name, rule in var.firewall_application_rules : name => {
      source_addresses  = flatten([for vnet in rule.source_vnets : local.vnet_address_spaces[vnet]])
      destination_fqdns = rule.destination_fqdns
      protocols         = rule.protocols
    }
  }

  public_ports = { for name, rule in var.firewall_dnat_rules : name => coalesce(rule.public_port, rule.port) }

  # Uses the VM's static IP from variables, not a module output, so the firewall does not wait for the VMs.
  firewall_dnat_rules = {
    for name, rule in var.firewall_dnat_rules : name => {
      destination_ports  = [tostring(local.public_ports[name])]
      translated_address = var.vms[rule.vm_key].private_ip_address
      translated_port    = rule.port
    }
  }

  # Every subnet a VM may use, keyed by hub or spoke key, then subnet name.
  subnet_ids = merge({ hub = module.hub.subnet_ids }, { for key, spoke in module.spokes : key => spoke.subnet_ids })
}
