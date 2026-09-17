terraform {
  required_version = ">= 1.9.0, < 2.0.0"
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = ">= 4.81.0, < 5.0.0"
    }
  }
}

# First half of the peering; address spaces must not overlap and one direction alone does not connect anything.
resource "azurerm_virtual_network_peering" "first_to_second" {
  name                         = "${var.first.name}-to-${var.second.name}"
  resource_group_name          = var.first.resource_group_name
  virtual_network_name         = var.first.name
  remote_virtual_network_id    = var.second.id
  allow_virtual_network_access = true
  allow_forwarded_traffic      = var.allow_forwarded_traffic
  allow_gateway_transit        = var.use_first_gateway
}

# Return half; peering is not transitive and does not bypass either VNet's NSGs or routes.
resource "azurerm_virtual_network_peering" "second_to_first" {
  name                         = "${var.second.name}-to-${var.first.name}"
  resource_group_name          = var.second.resource_group_name
  virtual_network_name         = var.second.name
  remote_virtual_network_id    = var.first.id
  allow_virtual_network_access = true
  allow_forwarded_traffic      = var.allow_forwarded_traffic
  use_remote_gateways          = var.use_first_gateway

  depends_on = [azurerm_virtual_network_peering.first_to_second]
}