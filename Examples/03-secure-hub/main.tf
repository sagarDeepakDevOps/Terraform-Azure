module "resource_group" {
  source   = "../../Modules/ResourceGroups"
  name     = "${var.prefix}-rg"
  location = var.location
  tags     = var.tags
}

module "hub" {
  source              = "../../Modules/Vnet"
  name                = "${var.prefix}-vnet"
  resource_group_name = module.resource_group.name
  location            = var.location
  address_space       = ["10.40.0.0/16"]
  subnets = {
    AzureFirewallSubnet = { address_prefixes = ["10.40.0.0/26"] }
    AzureBastionSubnet  = { address_prefixes = ["10.40.1.0/26"] }
    GatewaySubnet       = { address_prefixes = ["10.40.2.0/27"] }
  }
  tags = var.tags
}

module "spoke" {
  source              = "../../Modules/Vnet"
  name                = "${var.prefix}-spoke"
  resource_group_name = module.resource_group.name
  location            = var.location
  address_space       = ["10.41.0.0/16"]
  subnets = {
    workload = { address_prefixes = ["10.41.1.0/24"] }
  }
  tags = var.tags
}

module "firewall" {
  source                  = "../../Modules/Vnet/Firewalls"
  name                    = "${var.prefix}-fw"
  resource_group_name     = module.resource_group.name
  location                = var.location
  subnet_id               = module.hub.subnet_ids["AzureFirewallSubnet"]
  source_address_prefixes = ["10.41.0.0/16"]
  tags                    = var.tags
}

module "bastion" {
  source              = "../../Modules/Vnet/Bastion"
  count               = var.enable_bastion ? 1 : 0
  name                = "${var.prefix}-bastion"
  resource_group_name = module.resource_group.name
  location            = var.location
  subnet_id           = module.hub.subnet_ids["AzureBastionSubnet"]
  tags                = var.tags
}

module "vpn" {
  source              = "../../Modules/Vnet/VPNGateway"
  count               = var.enable_vpn ? 1 : 0
  name                = "${var.prefix}-vpn"
  resource_group_name = module.resource_group.name
  location            = var.location
  subnet_id           = module.hub.subnet_ids["GatewaySubnet"]
  on_premises         = var.on_premises
  shared_key          = var.vpn_shared_key
  tags                = var.tags
}

module "peering" {
  source                  = "../../Modules/Vnet/Peering"
  allow_forwarded_traffic = true
  use_first_gateway       = var.enable_vpn
  first = {
    name = module.hub.name, id = module.hub.id, resource_group_name = module.resource_group.name
  }
  second = {
    name = module.spoke.name, id = module.spoke.id, resource_group_name = module.resource_group.name
  }

  depends_on = [module.vpn]
}

module "routes" {
  source              = "../../Modules/Vnet/routeTables"
  name                = "${var.prefix}-egress-rt"
  resource_group_name = module.resource_group.name
  location            = var.location
  subnet_ids          = { workload = module.spoke.subnet_ids["workload"] }
  routes = {
    firewall_default = {
      address_prefix         = "0.0.0.0/0"
      next_hop_type          = "VirtualAppliance"
      next_hop_in_ip_address = module.firewall.private_ip_address
    }
  }
  tags = var.tags
}

module "workload_nsg" {
  source              = "../../Modules/Vnet/NSG"
  name                = "${var.prefix}-workload-nsg"
  resource_group_name = module.resource_group.name
  location            = var.location
  subnet_ids          = { workload = module.spoke.subnet_ids["workload"] }
  rules = {
    bastion_ssh = {
      priority = 100, destination_port_range = "22", source_address_prefix = "10.40.1.0/26"
    }
    bastion_rdp = {
      priority = 110, destination_port_range = "3389", source_address_prefix = "10.40.1.0/26"
    }
    deny_other_inbound = {
      priority = 4096, access = "Deny", protocol = "*", destination_port_range = "*", source_address_prefix = "*"
    }
  }
  tags = var.tags
}