terraform {
  required_version = ">= 1.9.0, < 2.0.0"
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = ">= 4.81.0, < 5.0.0"
    }
  }
}

# Purpose: Define user-selected next hops for traffic leaving associated subnets.
# Creation: AzureRM creates the route table, then expands var.routes into named
# destination-prefix/next-hop entries. VirtualAppliance routes also need a reachable
# next_hop_in_ip_address, normally obtained from a created firewall's output.
# Behavior: The BGP setting controls whether learned gateway routes propagate;
# Azure evaluates these routes together with its routing rules and system routes.
# Important: A route is not an NSG allow rule and does not create its next-hop
# appliance. An incorrect default route can disconnect every associated workload.
resource "azurerm_route_table" "this" {
  name                          = var.name
  resource_group_name           = var.resource_group_name
  location                      = var.location
  bgp_route_propagation_enabled = var.bgp_route_propagation_enabled
  tags                          = var.tags

  dynamic "route" {
    for_each = var.routes
    content {
      name                   = route.key
      address_prefix         = route.value.address_prefix
      next_hop_type          = route.value.next_hop_type
      next_hop_in_ip_address = route.value.next_hop_in_ip_address
    }
  }
}

# Purpose: Make the route table effective on the selected workload subnets.
# Creation: for_each creates one binding per named subnet, referencing the existing
# subnet ID and new table ID. Those references order the attachment after both.
# Important: A subnet has one route-table association. Do not blindly apply a
# workload default route to GatewaySubnet or a managed-service subnet; those
# services have their own required routing behavior and return-path constraints.
resource "azurerm_subnet_route_table_association" "this" {
  for_each       = var.subnet_ids
  subnet_id      = each.value
  route_table_id = azurerm_route_table.this.id
}