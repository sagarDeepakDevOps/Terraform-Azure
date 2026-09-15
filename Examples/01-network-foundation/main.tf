# Purpose: Create the owning resource group for this independently deployed network lab.
# Creation: Call the local ResourceGroups module with this root's naming, region and
# tags. Its outputs are reused below, establishing dependencies without manual ordering.
module "resource_group" {
  source = "../../Modules/ResourceGroups"

  name     = "${var.prefix}-rg"
  location = var.location
  tags     = var.tags
}

# Purpose: Create the hub VNet and its shared subnet using the reusable Vnet module.
# Creation: Pass the new group's name/location and the 10.10.0.0/16 address space;
# the child subnet map creates shared at 10.10.1.0/24 after the VNet exists.
# Important: This is topology only; no VM, gateway or firewall is created implicitly.
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

# Purpose: Demonstrate reusing the same module for a separate workload VNet.
# Creation: Change the name/address inputs and request web/app subnets within
# 10.20.0.0/16. The group output orders creation, and named subnet IDs are exported.
# Important: The ranges do not overlap the hub; only web receives this lab's NSG below.
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

# Purpose: Connect hub and spoke with both directional Azure VNet peering resources.
# Creation: Pass each created VNet's name, ID and group to the Peering module.
# Terraform waits for those outputs before creating the pair; no gateway transit
# is requested here. Peering alone does not share DNS links or allow all NSG traffic.
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

# Purpose: Allow only the illustrated hub-to-web HTTPS path on the spoke web subnet.
# Creation: Build an NSG with priority-100 HTTPS allow and a later explicit inbound
# deny, then associate it with the named web subnet ID returned by the VNet module.
# Important: This overrides broader default inbound allowances on web, not on app.
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

# Purpose: Demonstrate a subnet route table without depending on a paid appliance.
# Creation: Associate web with a UDR that discards 192.0.2.0/24 using next_hop_type
# None. This is a reserved documentation range, not a fictional firewall address.
# Important: The route does not give workloads Internet egress or create a gateway.
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

# Purpose: Provide a shared internal DNS namespace for the two example VNets.
# Creation: Create internal.example and explicitly link both VNet IDs in one module
# call. Those references order links after network creation.
# Important: Peering did not create these links, and no application DNS records are seeded.
module "private_dns" {
  source = "../../Modules/Vnet/PrivateDNS"

  name                = "internal.example"
  resource_group_name = module.resource_group.name
  virtual_network_ids = { hub = module.hub.id, spoke = module.spoke.id }
  tags                = var.tags
}