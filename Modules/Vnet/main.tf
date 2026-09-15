# Purpose: Create the private IP network that hosts workload and service subnets.
# Creation: AzureRM creates this VNet in the supplied resource group/region using
# address_space and dns_servers. An empty DNS list means Azure-provided DNS.
# References to a resource-group output let Terraform wait for that group to exist.
# Important: Pick ranges that do not overlap networks you will peer or connect by
# VPN. A VNet alone creates no VM, firewall, public endpoint or Internet gateway.
# Subnets are deliberately managed separately below; do not add inline subnet
# blocks here as well, or two Terraform resource types can compete for ownership.
resource "azurerm_virtual_network" "this" {
  name                = var.name
  resource_group_name = var.resource_group_name
  location            = var.location
  address_space       = var.address_space
  dns_servers         = var.dns_servers
  tags                = var.tags
}

# Purpose: Turn the caller's named subnet definitions into children of this VNet.
# Creation: Load the ./subnets module and pass the created VNet name, group and map
# of subnet settings. The VNet resource reference supplies the creation dependency;
# the child module's for_each creates one subnet for each stable map key.
# Important: The resulting subnet_ids output lets callers attach NSGs, routes,
# appliances or private endpoints explicitly; none is added automatically here.
module "subnets" {
  source = "./subnets"

  resource_group_name  = var.resource_group_name
  virtual_network_name = azurerm_virtual_network.this.name
  subnets              = var.subnets
}