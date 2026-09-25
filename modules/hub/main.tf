module "vnet" {
  source = "../networking/vnet"

  name                = "${var.name_prefix}-hub-vnet"
  resource_group_name = var.resource_group_name
  location            = var.location
  address_space       = var.address_space
  tags                = var.tags

  # A subnet that routes through the firewall is private, so the firewall is its only way out.
  subnets = {
    for key, subnet in var.subnets : key => {
      address_prefixes                = subnet.address_prefixes
      default_outbound_access_enabled = !subnet.route_via_firewall
    }
  }
}

# Every packet leaving a spoke passes through here: to the Internet, to another spoke, or back to a client.
module "firewall" {
  source = "../networking/firewall"

  name                 = "${var.name_prefix}-hub-fw"
  resource_group_name  = var.resource_group_name
  location             = var.location
  sku_tier             = var.firewall_sku_tier
  subnet_id            = module.vnet.subnet_ids["AzureFirewallSubnet"]
  management_subnet_id = try(module.vnet.subnet_ids["AzureFirewallManagementSubnet"], null)
  dnat_rules           = var.firewall_dnat_rules
  network_rules        = var.firewall_network_rules
  application_rules    = var.firewall_application_rules
  tags                 = var.tags
}

# SSH to any VM, in the hub or a spoke, without giving it a public IP.
module "bastion" {
  source = "../networking/bastion"

  name                = "${var.name_prefix}-hub-bastion"
  resource_group_name = var.resource_group_name
  location            = var.location
  sku                 = var.bastion_sku
  subnet_id           = module.vnet.subnet_ids["AzureBastionSubnet"]
  tags                = var.tags
}

# Only subnets that hold VMs get an NSG.
module "nsgs" {
  source   = "../networking/nsg"
  for_each = local.vm_subnets

  name                = "${var.name_prefix}-hub-${each.key}-nsg"
  resource_group_name = var.resource_group_name
  location            = var.location
  rules               = each.value.nsg_rules
  subnet_ids          = { (each.key) = module.vnet.subnet_ids[each.key] }
  tags                = var.tags
}

# Internet traffic from hub VMs goes through the firewall; spoke ranges are more specific and stay on the peering.
module "route_table" {
  source = "../networking/route-table"
  count  = length(local.routed_subnets) > 0 ? 1 : 0

  name                = "${var.name_prefix}-hub-rt"
  resource_group_name = var.resource_group_name
  location            = var.location
  subnet_ids          = { for key in keys(local.routed_subnets) : key => module.vnet.subnet_ids[key] }
  tags                = var.tags

  routes = {
    default-via-hub-firewall = {
      address_prefix         = "0.0.0.0/0"
      next_hop_type          = "VirtualAppliance"
      next_hop_in_ip_address = module.firewall.private_ip_address
    }
  }
}
