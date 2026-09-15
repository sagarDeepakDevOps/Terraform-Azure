terraform {
  required_version = ">= 1.9.0, < 2.0.0"
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = ">= 4.81.0, < 5.0.0"
    }
  }
}

# Purpose: Create a private Synapse workspace for future analytics/query workloads.
# Creation: Azure provisions the named workspace and its service-managed resource
# group, associates the existing ADLS filesystem URL and creates a system identity.
# The supplied synapseadmin password initializes SQL administration; the managed VNet
# is enabled while public workspace network access is disabled.
# Important: filesystem_id is a DFS filesystem URL, not a blob-container ARM ID.
# The caller creates SQL/SqlOnDemand/Dev private endpoints and later configures managed
# lake endpoints from a runner that can reach the private Dev data-plane API.
# No dedicated SQL pool, Spark pool, dataset or pipeline is created here. The SQL
# password remains in state; production authentication and recovery need separate design.
resource "azurerm_synapse_workspace" "this" {
  name                                 = var.name
  resource_group_name                  = var.resource_group_name
  location                             = var.location
  managed_resource_group_name          = "${var.name}-managed-rg"
  storage_data_lake_gen2_filesystem_id = var.filesystem_id
  sql_administrator_login              = "synapseadmin"
  sql_administrator_login_password     = var.administrator_password
  managed_virtual_network_enabled      = true
  public_network_access_enabled        = false
  tags                                 = var.tags

  identity {
    type = "SystemAssigned"
  }
}

# Purpose: Let the Synapse workspace identity read/write its associated data lake.
# Creation: Assign Storage Blob Data Contributor at the supplied storage account
# scope to the system identity returned by workspace creation.
# Important: A role grant does not approve managed private endpoints or configure
# client DNS. Confirm both permission propagation and the lake network path before queries.
resource "azurerm_role_assignment" "storage" {
  scope                = var.storage_account_id
  role_definition_name = "Storage Blob Data Contributor"
  principal_id         = azurerm_synapse_workspace.this.identity[0].principal_id
  principal_type       = "ServicePrincipal"
}