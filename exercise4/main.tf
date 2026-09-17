data "azurerm_resource_group" "this" {
  name = var.resource_group_name
}

# Finds the subnets exercise3 created, so this exercise needs only their names.
data "azurerm_subnet" "this" {
  for_each = var.nsgs

  name                 = each.value.subnet_name
  virtual_network_name = "${var.prefix}-${each.value.vnet_key}-vnet"
  resource_group_name  = data.azurerm_resource_group.this.name
}

# Exercise 4: one NSG per subnet, carrying only that subnet's own rules.
module "nsgs" {
  source   = "../modules/networking/nsg"
  for_each = var.nsgs

  name                = "${var.prefix}-${each.key}-nsg"
  resource_group_name = data.azurerm_resource_group.this.name
  location            = data.azurerm_resource_group.this.location
  subnet_ids          = { (each.value.subnet_name) = data.azurerm_subnet.this[each.key].id }
  rules               = each.value.rules
  tags                = var.tags
}
