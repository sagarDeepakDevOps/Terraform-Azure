terraform {
  required_version = ">= 1.9.0, < 2.0.0"
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = ">= 4.81.0, < 5.0.0"
    }
  }
}

# Purpose: Give a supported Azure service a private network entry point in a VNet.
# Creation: Azure allocates a managed NIC/private IP in subnet_id and connects it
# to resource_id using the service's group IDs in subresource_names, such as blob,
# vault or sqlServer. The DNS zone group requests service records in the supplied
# zones; the caller must create/link zones appropriate to that service first.
# Authorization: is_manual_connection=false requests automatic approval, which
# still requires sufficient permissions on the target; it does not bypass approval.
# Important: Use an appropriate non-delegated endpoint subnet. This block does not
# disable the service's public endpoint or grant its data roles. Callers separately
# enforce public-access settings and provide client routing, DNS and authentication.
resource "azurerm_private_endpoint" "this" {
  name                = var.name
  resource_group_name = var.resource_group_name
  location            = var.location
  subnet_id           = var.subnet_id
  tags                = var.tags

  private_service_connection {
    name                           = "${var.name}-connection"
    private_connection_resource_id = var.resource_id
    subresource_names              = var.subresource_names
    is_manual_connection           = false
  }

  private_dns_zone_group {
    name                 = "default"
    private_dns_zone_ids = var.private_dns_zone_ids
  }
}