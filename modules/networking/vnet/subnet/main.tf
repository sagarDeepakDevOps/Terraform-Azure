# Azure reserves the first four and the last address of every subnet range.
resource "azurerm_subnet" "this" {
  name                            = var.name
  resource_group_name             = var.resource_group_name
  virtual_network_name            = var.virtual_network_name
  address_prefixes                = var.address_prefixes
  default_outbound_access_enabled = var.default_outbound_access_enabled
}
