terraform {
  required_version = ">= 1.9.0, < 2.0.0"
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = ">= 4.81.0, < 5.0.0"
    }
  }
}

# Purpose: Create the Azure Data Factory service that owns data orchestration assets.
# Creation: AzureRM provisions the globally named factory with a managed virtual
# network and system-assigned identity. Runtime, linked-service, endpoint and pipeline
# resources below reference its ID and therefore follow its creation.
# Security: Public networking is disabled. The caller supplies inbound private access
# where needed, while managed endpoints below provide the runtime's outbound lake path.
# Important: A factory is not a running ETL job; identities, approval, datasets,
# activities and workload-specific authoring connectivity remain separate concerns.
resource "azurerm_data_factory" "this" {
  name                            = var.name
  resource_group_name             = var.resource_group_name
  location                        = var.location
  managed_virtual_network_enabled = true
  public_network_enabled          = false
  tags                            = var.tags

  identity {
    type = "SystemAssigned"
  }
}

# Purpose: Select a managed-VNet Azure integration runtime for lake-connected activities.
# Creation: Add managed-vnet to the new factory in the requested region and enable
# virtual-network use. The linked service below explicitly selects this runtime.
# Its time-to-live setting is zero rather than reserving a warm TTL window here.
# Important: Runtime configuration does not execute a pipeline or approve private
# endpoints. Pipeline/activity execution can still incur charges when requested.
resource "azurerm_data_factory_integration_runtime_azure" "this" {
  name                    = "managed-vnet"
  data_factory_id         = azurerm_data_factory.this.id
  location                = var.location
  virtual_network_enabled = true
  time_to_live_min        = 0
}

# Purpose: Describe how Data Factory activities should connect to the ADLS Gen2 lake.
# Creation: Store the caller's DFS endpoint URL, select the managed-VNet runtime and
# enable the factory's managed identity instead of embedding a storage key.
# The factory/runtime references order this connection definition after both exist.
# Important: A linked service is connection metadata, not proof of successful access.
# The identity grant and approved Blob/DFS managed endpoints below are also needed.
resource "azurerm_data_factory_linked_service_data_lake_storage_gen2" "this" {
  name                     = "data-lake"
  data_factory_id          = azurerm_data_factory.this.id
  url                      = var.storage_dfs_endpoint
  use_managed_identity     = true
  integration_runtime_name = azurerm_data_factory_integration_runtime_azure.this.name
}

# Purpose: Request private lake connectivity from inside Data Factory's managed VNet.
# Creation: for_each requests both dfs and blob service groups on storage_account_id,
# creating a managed endpoint beneath the new factory for each. These are separate
# from the ordinary private endpoints used by clients in the example's own VNet.
# Important: The storage owner must approve the connection requests before data
# access works. Terraform creating the request is not approval or a data-role grant.
resource "azurerm_data_factory_managed_private_endpoint" "this" {
  for_each           = toset(["dfs", "blob"])
  name               = "lake-${each.key}"
  data_factory_id    = azurerm_data_factory.this.id
  target_resource_id = var.storage_account_id
  subresource_name   = each.key
}

# Purpose: Authorize the Data Factory identity to read/write application lake blobs.
# Creation: Grant Storage Blob Data Contributor on the selected account to the new
# factory's principal ID. References order the grant after that identity exists.
# Important: This permission is independent of endpoint approval and network access,
# can take time to propagate, and should be narrowed for specific production datasets.
resource "azurerm_role_assignment" "storage" {
  scope                = var.storage_account_id
  role_definition_name = "Storage Blob Data Contributor"
  principal_id         = azurerm_data_factory.this.identity[0].principal_id
  principal_type       = "ServicePrincipal"
}

# Purpose: Provide a real, minimal orchestration pipeline for the presentation.
# Creation: jsonencode serializes one Wait activity into Data Factory's activity
# schema and Azure stores it beneath the factory. It waits one second only when
# the pipeline is run; Terraform does not execute this activity during deployment.
# Important: No schedule, copy activity or customer data movement is configured.
# Extend it only after confirming linked-service authorization and private connectivity.
resource "azurerm_data_factory_pipeline" "this" {
  name            = "demo-pipeline"
  data_factory_id = azurerm_data_factory.this.id
  activities_json = jsonencode([{
    name           = "WaitForDemo"
    type           = "Wait"
    typeProperties = { waitTimeInSeconds = 1 }
  }])
}