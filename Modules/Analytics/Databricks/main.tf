terraform {
  required_version = ">= 1.9.0, < 2.0.0"
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = ">= 4.81.0, < 5.0.0"
    }
  }
}

# Purpose: Create the Azure identity bridge Databricks can use for lake access.
# Creation: AzureRM provisions an access connector with a system-assigned identity;
# the storage grant below authorizes that principal without an account key.
# Important: The connector is not a cluster or a Unity Catalog storage credential.
# Databricks account/workspace configuration must explicitly use its output ID later.
resource "azurerm_databricks_access_connector" "this" {
  name                = "${var.name}-connector"
  resource_group_name = var.resource_group_name
  location            = var.location
  tags                = var.tags

  identity {
    type = "SystemAssigned"
  }
}

# Purpose: Provision a Premium Databricks workspace with VNet-injected cluster networking.
# Creation: Azure uses the caller's VNet, delegated host/container subnet names and
# NSG association IDs, and creates its separate managed resource group. The caller
# first establishes NAT egress; Azure's required Databricks NSG rules remain enabled.
# Networking: no_public_ip disables public IPs on future classic cluster nodes;
# public_network_access_enabled=true intentionally keeps the authenticated workspace
# UI public. The provider's public_subnet name describes the host subnet, not a
# requirement to place public addresses on nodes.
# Important: This provisions no cluster, job, notebook, metastore or catalog object.
# VNet/NSG wiring and a lake role do not complete Unity Catalog configuration, and
# future compute plus the lab's networking/storage can incur ongoing charges.
resource "azurerm_databricks_workspace" "this" {
  name                                  = var.name
  resource_group_name                   = var.resource_group_name
  location                              = var.location
  sku                                   = "premium"
  managed_resource_group_name           = "${var.name}-managed-rg"
  public_network_access_enabled         = true
  network_security_group_rules_required = "AllRules"
  tags                                  = var.tags

  custom_parameters {
    no_public_ip                                         = true
    virtual_network_id                                   = var.virtual_network_id
    public_subnet_name                                   = var.public_subnet_name
    private_subnet_name                                  = var.private_subnet_name
    public_subnet_network_security_group_association_id  = var.public_nsg_association_id
    private_subnet_network_security_group_association_id = var.private_nsg_association_id
  }
}

# Purpose: Give the access connector identity permission to use the selected lake.
# Creation: Assign Storage Blob Data Contributor on storage_account_id to the
# connector's system principal after Azure creates that identity.
# Important: Configure a Databricks storage credential/external location to use this
# connector. The grant itself neither mounts the lake nor provides a network path.
resource "azurerm_role_assignment" "storage" {
  scope                = var.storage_account_id
  role_definition_name = "Storage Blob Data Contributor"
  principal_id         = azurerm_databricks_access_connector.this.identity[0].principal_id
  principal_type       = "ServicePrincipal"
}