terraform {
  required_version = ">= 1.9.0, < 2.0.0"
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = ">= 4.81.0, < 5.0.0"
    }
  }
}

# Purpose: Create the first VNet's half of a direct private peering connection.
# Creation: AzureRM adds the peering to var.first and points it at var.second.id.
# Resource-derived inputs make both VNets exist before this connection is created.
# Options: Forwarded traffic allows an appliance's forwarded packets; gateway
# transit lets the first VNet offer its already-created gateway to its peer.
# Important: Address spaces must not overlap, and a single directional peering
# does not complete the connection. Peering also does not create transit routing
# through third VNets or automatically share private DNS zone links.
resource "azurerm_virtual_network_peering" "first_to_second" {
  name                         = "${var.first.name}-to-${var.second.name}"
  resource_group_name          = var.first.resource_group_name
  virtual_network_name         = var.first.name
  remote_virtual_network_id    = var.second.id
  allow_virtual_network_access = true
  allow_forwarded_traffic      = var.allow_forwarded_traffic
  allow_gateway_transit        = var.use_first_gateway
}

# Purpose: Complete peering by creating the return connection on the second VNet.
# Creation: This reverses the names/IDs and explicitly waits for the first peering.
# When use_first_gateway is true, Azure configures this VNet to use the first
# VNet's gateway while the first half advertises allow_gateway_transit.
# Important: The gateway must already exist and the second VNet must meet Azure's
# remote-gateway restrictions. Peering permissions do not bypass either VNet's
# NSGs, service firewalls, DNS requirements or user-defined routes.
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