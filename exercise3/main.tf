data "azurerm_resource_group" "this" {
  name = var.resource_group_name
}

# Exercise 3: subnets are separate resources inside a VNet that already exists.
module "subnets" {
  source   = "../modules/networking/subnets"
  for_each = var.vnet_subnets

  resource_group_name  = data.azurerm_resource_group.this.name
  virtual_network_name = "${var.prefix}-${each.key}-vnet"
  subnets              = each.value
}
