# Private subnets: no implicit Internet egress, so every outbound flow has to go through the hub.
module "vnet" {
  source = "../networking/vnet"

  name                = "${var.name_prefix}-${var.name}-vnet"
  resource_group_name = var.resource_group_name
  location            = var.location
  address_space       = var.address_space
  tags                = var.tags

  subnets = {
    for key, subnet in var.subnets : key => {
      address_prefixes                = subnet.address_prefixes
      default_outbound_access_enabled = false
    }
  }
}

# One NSG per subnet, so a rule opened for one subnet cannot widen another.
module "nsgs" {
  source   = "../networking/nsg"
  for_each = var.subnets

  name                = "${var.name_prefix}-${var.name}-${each.key}-nsg"
  resource_group_name = var.resource_group_name
  location            = var.location
  rules               = each.value.nsg_rules
  subnet_ids          = { (each.key) = module.vnet.subnet_ids[each.key] }
  tags                = var.tags
}

# Anything not in this spoke or the hub, including other spokes and the Internet, goes to the firewall.
module "route_table" {
  source = "../networking/route-table"

  name                = "${var.name_prefix}-${var.name}-rt"
  resource_group_name = var.resource_group_name
  location            = var.location
  subnet_ids          = module.vnet.subnet_ids
  tags                = var.tags

  routes = {
    default-via-hub-firewall = {
      address_prefix         = "0.0.0.0/0"
      next_hop_type          = "VirtualAppliance"
      next_hop_in_ip_address = var.firewall_private_ip
    }
  }
}

module "peering" {
  source = "../networking/peering"

  hub = var.hub_vnet
  spoke = {
    name                = module.vnet.name
    id                  = module.vnet.id
    resource_group_name = var.resource_group_name
  }
}
