locals {
  # HTTP is open to the Internet on purpose; the probe rule is mandatory or every health check fails.
  http_rules = {
    allow_http_internet = {
      priority               = 100
      destination_port_range = tostring(var.http_port)
      source_address_prefix  = "Internet"
    }
    allow_lb_health_probe = {
      priority               = 110
      destination_port_range = tostring(var.http_port)
      source_address_prefix  = "AzureLoadBalancer"
    }
  }

  # SSH stays closed until a source range is named.
  ssh_rules = var.ssh_source_address_prefix == null ? {} : {
    allow_ssh_admin = {
      priority               = 120
      destination_port_range = "22"
      source_address_prefix  = var.ssh_source_address_prefix
    }
  }

  # Final catch-all, closing anything the rules above did not allow.
  deny_rules = {
    deny_other_inbound = {
      priority               = 4096
      access                 = "Deny"
      protocol               = "*"
      destination_port_range = "*"
      source_address_prefix  = "*"
    }
  }

  nsg_rules = merge(local.http_rules, local.ssh_rules, local.deny_rules)
}
