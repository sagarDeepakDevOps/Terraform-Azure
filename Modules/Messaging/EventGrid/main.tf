terraform {
  required_version = ">= 1.9.0, < 2.0.0"
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = ">= 4.81.0, < 5.0.0"
    }
  }
}

# Purpose: Expose supported events emitted by the selected Storage account to Event Grid.
# Creation: Azure creates a StorageAccounts system topic linked to storage_account_id
# and gives it a system-assigned identity. That ID orders creation after the source
# account, while the identity is used for authorized delivery to Service Bus below.
# Important: A system topic represents a real Azure event source; it is not a custom
# topic requiring an application to publish the Storage events manually.
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

# Purpose: Permit this Event Grid topic identity to deliver notifications to the queue.
# Creation: Grant Azure Service Bus Data Sender on the selected queue ID to the new
# topic's principal. The event subscription explicitly waits for this role assignment.
# Important: Queue scope limits the grant, but RBAC propagation may still delay first
# delivery. This provides authorization, not a receiver app or a network workaround.
resource "azurerm_role_assignment" "send" {
  scope                = var.service_bus_queue_id
  role_definition_name = "Azure Service Bus Data Sender"
  principal_id         = azurerm_eventgrid_system_topic.this.identity[0].principal_id
  principal_type       = "ServicePrincipal"
}

# Purpose: Forward BlobCreated notifications from the incoming container to Service Bus.
# Creation: Attach a subscription to the system topic, filter event type and subject
# prefix, select the queue endpoint, and use the topic's system identity for delivery.
# Azure handles delivery retries up to the configured attempt/1440-minute TTL limits
# after this subscription and its sender grant are created.
# Important: The notification contains event metadata, not the full blob contents.
# Delivery can be duplicated; consumers need idempotency. No Event Grid dead-letter
# destination is configured here, so monitor failures and design retention/recovery
# for events that cannot be delivered before their retry/TTL limits are exhausted.
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