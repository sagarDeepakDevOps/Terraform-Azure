terraform {
  required_version = ">= 1.9.0, < 2.0.0"
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = ">= 4.81.0, < 5.0.0"
    }
  }
}

resource "azurerm_servicebus_namespace" "this" {
  name                          = var.name
  resource_group_name           = var.resource_group_name
  location                      = var.location
  sku                           = "Standard"
  minimum_tls_version           = "1.2"
  local_auth_enabled            = false
  public_network_access_enabled = true
  tags                          = var.tags
}

resource "azurerm_servicebus_queue" "this" {
  name                                 = "orders"
  namespace_id                         = azurerm_servicebus_namespace.this.id
  default_message_ttl                  = "P7D"
  lock_duration                        = "PT30S"
  max_delivery_count                   = 5
  dead_lettering_on_message_expiration = true
  requires_duplicate_detection         = true
}

resource "azurerm_servicebus_topic" "this" {
  name                = "business-events"
  namespace_id        = azurerm_servicebus_namespace.this.id
  default_message_ttl = "P7D"
}

resource "azurerm_servicebus_subscription" "this" {
  name                                 = "audit"
  topic_id                             = azurerm_servicebus_topic.this.id
  max_delivery_count                   = 5
  dead_lettering_on_message_expiration = true
}