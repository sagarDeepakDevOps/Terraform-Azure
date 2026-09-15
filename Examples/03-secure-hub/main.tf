# Purpose: Create the dedicated resource group for this paid secure-hub demonstration.
# Creation: Other modules consume its output name so Azure creates the group first.
module "resource_group" {
  source   = "../../Modules/ResourceGroups"
  name     = "${var.prefix}-rg"
  location = var.location
  tags     = var.tags
}

# Purpose: Reserve the hub address space and Azure-required appliance subnet names.
# Creation: Build 10.40.0.0/16 with /26 Firewall/Bastion ranges and a /27 GatewaySubnet.
# These subnet IDs become inputs to the appliance modules after the VNet exists.
# Important: Creating reserved subnets alone does not deploy their paid appliances.
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

# Purpose: Create a separate workload network to demonstrate routed hub-spoke traffic.
# Creation: Build 10.41.0.0/16 and its workload subnet in the shared lab group.
# Important: No workload VM is included; routes/NSG below configure the empty subnet.
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

# Purpose: Deploy the real Standard Firewall used by the spoke's default route.
# Creation: Use the hub's AzureFirewallSubnet ID and allow configured repository
# traffic from the spoke CIDR. The private IP output becomes the UDR next hop below.
# Important: Firewall is created by default in this lab and has significant recurring
# cost. A valid route must reference its actual output, not a guessed private address.
module "firewall" {
  source                  = "../../Modules/Vnet/Firewalls"
  name                    = "${var.prefix}-fw"
  resource_group_name     = module.resource_group.name
  location                = var.location
  subnet_id               = module.hub.subnet_ids["AzureFirewallSubnet"]
  source_address_prefixes = ["10.41.0.0/16"]
  tags                    = var.tags
}

# Purpose: Optionally provide managed administration from the dedicated Bastion subnet.
# Creation: count creates one Standard Bastion only when enable_bastion is true.
# Important: VMs/login permissions remain separate, and idle Bastion still has charges.
module "bastion" {
  source              = "../../Modules/Vnet/Bastion"
  count               = var.enable_bastion ? 1 : 0
  name                = "${var.prefix}-bastion"
  resource_group_name = module.resource_group.name
  location            = var.location
  subnet_id           = module.hub.subnet_ids["AzureBastionSubnet"]
  tags                = var.tags
}

# Purpose: Optionally add a zone-redundant VPN gateway and a configured S2S peer.
# Creation: Use GatewaySubnet and pass optional on-premises details plus the sensitive
# shared key. The child creates the connection only if remote details are provided.
# Important: The remote device is configured outside this code; a gateway object
# alone does not connect a laptop or establish a working site-to-site tunnel.
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

# Purpose: Connect the spoke to the hub, allowing appliance-forwarded traffic.
# Creation: Pass both VNet IDs and enable gateway transit only when enable_vpn is
# selected. depends_on waits for the optional VPN module before requesting transit.
# Important: Peering is not transitive; routes and return paths must still be designed
# explicitly. The gateway setting does not force all private traffic through Firewall.
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

# Purpose: Send the spoke workload subnet's default traffic toward Azure Firewall.
# Creation: Bind a 0.0.0.0/0 VirtualAppliance route using the actual firewall private
# IP output, ordering route creation after the firewall is available.
# Important: No equivalent default route is attached to the reserved hub gateway subnets.
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

# Purpose: Restrict workload administration to the hub's Bastion source subnet.
# Creation: Attach SSH/RDP allow rules for 10.40.1.0/26 and a final inbound deny to
# the spoke workload subnet. The subnet ID creates the implicit network dependency.
# Important: This grants network reachability only, not Azure permissions or guest logins.
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