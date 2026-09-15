terraform {
  required_version = ">= 1.9.0, < 2.0.0"
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = ">= 4.81.0, < 5.0.0"
    }
  }
}

# Purpose: Create an internal DNS namespace, usually a service-specific privatelink
# zone so a normal service hostname can resolve to its private endpoint address.
# Creation: AzureRM creates the zone in the requested resource group. DNS zones
# are not placed inside a subnet; links below connect them to client VNets.
# Important: Use Azure's exact zone name for the chosen service. This resource
# creates the zone, not a private endpoint, network route or service access grant.
resource "azurerm_private_dns_zone" "this" {
  name                = var.name
  resource_group_name = var.resource_group_name
  tags                = var.tags
}

# Purpose: Let each explicitly linked VNet resolve records from this private zone.
# Creation: for_each binds every named VNet ID to the new zone; the zone reference
# creates the ordering dependency. registration_enabled optionally registers VM
# records, and should remain false for the private-endpoint service zones here.
# Important: VNet peering does not share this link. Custom DNS clients may need
# forwarding or a resolver in a linked VNet; creating the link does not configure
# an on-premises DNS server or make private endpoints reachable from the Internet.
resource "azurerm_private_dns_zone_virtual_network_link" "this" {
  for_each              = var.virtual_network_ids
  name                  = each.key
  resource_group_name   = var.resource_group_name
  private_dns_zone_name = azurerm_private_dns_zone.this.name
  virtual_network_id    = each.value
  registration_enabled  = var.registration_enabled
  tags                  = var.tags
}