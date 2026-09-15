module "resource_group" {
  source = "../../Modules/ResourceGroups"

  name     = "${var.prefix}-rg"
  location = var.location
  tags     = var.tags
}

module "hub" {
  source = "../../Modules/Vnet"

  name                = "${var.prefix}-hub-vnet"
  resource_group_name = module.resource_group.name
  location            = module.resource_group.location
  address_space       = ["10.10.0.0/16"]
  subnets = {
    shared = { address_prefixes = ["10.10.1.0/24"] }
  }
  tags = var.tags
}

module "spoke" {
  source = "../../Modules/Vnet"

  name                = "${var.prefix}-spoke-vnet"
  resource_group_name = module.resource_group.name
  location            = module.resource_group.location
  address_space       = ["10.20.0.0/16"]
  subnets = {
    web = { address_prefixes = ["10.20.1.0/24"] }
    app = { address_prefixes = ["10.20.2.0/24"] }
  }
  tags = var.tags
}

module "peering" {
  source = "../../Modules/Vnet/Peering"

  first = {
    name                = module.hub.name
    id                  = module.hub.id
    resource_group_name = module.resource_group.name
  }
  second = {
    name                = module.spoke.name
    id                  = module.spoke.id
    resource_group_name = module.resource_group.name
  }
}

module "web_nsg" {
  source = "../../Modules/Vnet/NSG"

  name                = "${var.prefix}-web-nsg"
  resource_group_name = module.resource_group.name
  location            = module.resource_group.location
  subnet_ids          = { web = module.spoke.subnet_ids["web"] }
  rules = {
    allow_hub_https = {
      priority               = 100
      destination_port_range = "443"
      source_address_prefix  = "10.10.0.0/16"
    }
    deny_other_inbound = {
      priority               = 4096
      access                 = "Deny"
      protocol               = "*"
      destination_port_range = "*"
      source_address_prefix  = "*"
    }
  }
  tags = var.tags
}

module "routes" {
  source = "../../Modules/Vnet/routeTables"

  name                = "${var.prefix}-web-rt"
  resource_group_name = module.resource_group.name
  location            = module.resource_group.location
  subnet_ids          = { web = module.spoke.subnet_ids["web"] }
  routes = {
    discard_documentation_range = {
      address_prefix = "192.0.2.0/24"
      next_hop_type  = "None"
    }
  }
  tags = var.tags
}

module "private_dns" {
  source = "../../Modules/Vnet/PrivateDNS"

  name                = "internal.example"
  resource_group_name = module.resource_group.name
  virtual_network_ids = { hub = module.hub.id, spoke = module.spoke.id }
  tags                = var.tags
}