terraform {
  required_version = ">= 1.9.0, < 2.0.0"
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = ">= 4.81.0, < 5.0.0"
    }
  }
}

resource "azurerm_eventhub_namespace" "this" {
  name                          = var.name
  resource_group_name           = var.resource_group_name
  location                      = var.location
  sku                           = "Standard"
  capacity                      = 1
  auto_inflate_enabled          = true
  maximum_throughput_units      = 2
  minimum_tls_version           = "1.2"
  local_authentication_enabled  = false
  public_network_access_enabled = true
  tags                          = var.tags
}

resource "azurerm_eventhub" "this" {
  name            = "telemetry"
  namespace_id    = azurerm_eventhub_namespace.this.id
  partition_count = 2

  retention_description {
    cleanup_policy          = "Delete"
    retention_time_in_hours = 24
  }
}

resource "azurerm_eventhub_consumer_group" "this" {
  name                = "analytics"
  namespace_name      = azurerm_eventhub_namespace.this.name
  eventhub_name       = azurerm_eventhub.this.name
  resource_group_name = var.resource_group_name
}