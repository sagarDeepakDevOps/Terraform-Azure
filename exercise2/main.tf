# Looks up the group exercise1 created, so this exercise needs only its name.
data "azurerm_resource_group" "this" {
  name = var.resource_group_name
}

# Exercise 2: one VNet per map key. Subnets come later, in exercise3.
module "vnets" {
  source   = "../modules/networking/vnet"
  for_each = var.vnets

  name                = "${var.prefix}-${each.key}-vnet"
  resource_group_name = data.azurerm_resource_group.this.name
  location            = data.azurerm_resource_group.this.location
  address_space       = each.value.address_space
  tags                = var.tags
}
