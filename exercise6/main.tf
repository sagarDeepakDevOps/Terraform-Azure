data "azurerm_resource_group" "this" {
  name = var.resource_group_name
}

data "azurerm_subnet" "this" {
  for_each = var.nat_gateways

  name                 = each.value.subnet_name
  virtual_network_name = "${var.prefix}-${each.value.vnet_key}-vnet"
  resource_group_name  = data.azurerm_resource_group.this.name
}

# Exercise 6: outbound-only Internet, so exercise7 can build VMs with no public IP.
module "nat_gateways" {
  source   = "../modules/networking/natgateway"
  for_each = var.nat_gateways

  name                = "${var.prefix}-${each.key}-nat"
  resource_group_name = data.azurerm_resource_group.this.name
  location            = data.azurerm_resource_group.this.location
  subnet_ids          = { (each.value.subnet_name) = data.azurerm_subnet.this[each.key].id }
  tags                = var.tags
}
