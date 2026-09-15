terraform {
  required_version = ">= 1.9.0, < 2.0.0"
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = ">= 4.81.0, < 5.0.0"
    }
  }
}

resource "azurerm_eventgrid_system_topic" "this" {
  name                = var.name
  resource_group_name = var.resource_group_name
  location            = var.location
  source_resource_id  = var.storage_account_id
  topic_type          = "Microsoft.Storage.StorageAccounts"
  tags                = var.tags

  identity {
    type = "SystemAssigned"
  }
}

resource "azurerm_role_assignment" "send" {
  scope                = var.service_bus_queue_id
  role_definition_name = "Azure Service Bus Data Sender"
  principal_id         = azurerm_eventgrid_system_topic.this.identity[0].principal_id
  principal_type       = "ServicePrincipal"
}

resource "azurerm_eventgrid_system_topic_event_subscription" "this" {
  name                          = "blob-created-to-orders"
  resource_group_name           = var.resource_group_name
  system_topic                  = azurerm_eventgrid_system_topic.this.name
  included_event_types          = ["Microsoft.Storage.BlobCreated"]
  service_bus_queue_endpoint_id = var.service_bus_queue_id

  delivery_identity {
    type = "SystemAssigned"
  }

  subject_filter {
    subject_begins_with = "/blobServices/default/containers/incoming/"
  }

  retry_policy {
    max_delivery_attempts = 10
    event_time_to_live    = 1440
  }

  depends_on = [azurerm_role_assignment.send]
}