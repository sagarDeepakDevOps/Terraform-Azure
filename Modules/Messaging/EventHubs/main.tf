terraform {
  required_version = ">= 1.9.0, < 2.0.0"
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = ">= 4.81.0, < 5.0.0"
    }
  }
}

# Purpose: Provision the streaming namespace that supplies Event Hubs throughput capacity.
# Creation: AzureRM creates Standard capacity at one throughput unit, with auto-inflate
# permitted up to two as load increases. The stream below references this namespace.
# Security: Require TLS 1.2 and Entra authentication; local keys are disabled while
# the public endpoint remains enabled for this demonstration.
# Important: Auto-inflate scales capacity up, not automatically back down. Capacity
# and ingestion are billable, and producers/consumers still need roles and connectivity.
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

# Purpose: Create the partitioned telemetry log consumed by streaming applications.
# Creation: Add telemetry to the new namespace with two partitions and Delete
# retention of 24 hours. This configures ordered logs within individual partitions,
# not a single global ordering guarantee across the entire stream.
# Important: Consumers must checkpoint and keep up within retention. Creating the
# stream does not publish events, install processors or preserve data indefinitely.
resource "azurerm_eventhub" "this" {
  name            = "telemetry"
  namespace_id    = azurerm_eventhub_namespace.this.id
  partition_count = 2

  retention_description {
    cleanup_policy          = "Delete"
    retention_time_in_hours = 24
  }
}

# Purpose: Give analytics consumers an independent view of the telemetry stream.
# Creation: Add an analytics consumer group using the new namespace/stream names;
# those references order it after the broker and event hub exist.
# Important: This is consumer metadata, not a running consumer, access grant or
# checkpoint store. The consuming SDK/application must manage those responsibilities.
resource "azurerm_eventhub_consumer_group" "this" {
  name                = "analytics"
  namespace_name      = azurerm_eventhub_namespace.this.name
  eventhub_name       = azurerm_eventhub.this.name
  resource_group_name = var.resource_group_name
}