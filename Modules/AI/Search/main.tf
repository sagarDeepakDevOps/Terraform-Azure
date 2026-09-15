terraform {
  required_version = ">= 1.9.0, < 2.0.0"
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = ">= 4.81.0, < 5.0.0"
    }
  }
}

# Purpose: Provision Azure AI Search capacity for future document/vector indexes.
# Creation: AzureRM creates a Basic service with one replica and one partition and
# enables a system-assigned identity for supported outbound service integrations.
# Security: Public networking and local API keys are disabled; failed authentication
# uses a Bearer challenge. The caller creates searchService private connectivity
# and grants clients the appropriate Search data/service roles.
# Important: This does not create indexes, load documents, build embeddings or attach
# indexers. Data-contributor rights differ from index-administration rights. One
# replica is a demo capacity choice and is billed even when no queries are running.
resource "azurerm_search_service" "this" {
  name                          = var.name
  resource_group_name           = var.resource_group_name
  location                      = var.location
  sku                           = "basic"
  replica_count                 = 1
  partition_count               = 1
  public_network_access_enabled = false
  local_authentication_enabled  = false
  authentication_failure_mode   = "http401WithBearerChallenge"
  tags                          = var.tags

  identity {
    type = "SystemAssigned"
  }
}