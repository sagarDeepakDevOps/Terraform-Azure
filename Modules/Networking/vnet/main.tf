# Address space must not overlap any network you intend to peer; an empty dns_servers list means Azure DNS.
resource "azurerm_virtual_network" "this" {
  name                = var.name
  resource_group_name = var.resource_group_name
  location            = var.location
  address_space       = var.address_space
  dns_servers         = var.dns_servers
  tags                = var.tags
}

# Loops over the caller's subnet map, creating one subnet per key; NSGs and routes are attached by the root, not here.
module "subnets" {
  source = "./subnets"

  resource_group_name  = var.resource_group_name
  virtual_network_name = azurerm_virtual_network.this.name
  subnets              = var.subnets
}