data "azurerm_resource_group" "this" {
  name = var.resource_group_name
}

# Finds both VNets exercise2 created.
data "azurerm_virtual_network" "this" {
  for_each = toset(flatten([for peering in var.vnet_peerings : [peering.first, peering.second]]))

  name                = "${var.prefix}-${each.value}-vnet"
  resource_group_name = data.azurerm_resource_group.this.name
}

# Exercise 5: both directions of a private VNet-to-VNet connection.
module "peerings" {
  source   = "../modules/networking/peering"
  for_each = var.vnet_peerings

  first = {
    name                = data.azurerm_virtual_network.this[each.value.first].name
    id                  = data.azurerm_virtual_network.this[each.value.first].id
    resource_group_name = data.azurerm_resource_group.this.name
  }
  second = {
    name                = data.azurerm_virtual_network.this[each.value.second].name
    id                  = data.azurerm_virtual_network.this[each.value.second].id
    resource_group_name = data.azurerm_resource_group.this.name
  }
}
