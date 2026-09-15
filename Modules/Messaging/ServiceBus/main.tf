terraform {
  required_version = ">= 1.9.0, < 2.0.0"
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = ">= 4.81.0, < 5.0.0"
    }
  }
}

# Purpose: Create the Service Bus broker namespace that owns queues and pub/sub topics.
# Creation: AzureRM provisions a globally named Standard namespace in the requested
# region; child queue/topic resources reference its ID and therefore wait for it.
# Security: TLS 1.2 is required and local shared-key authentication is disabled.
# This demo keeps an authenticated public endpoint; senders/receivers need Entra roles.
# Important: Standard is a cost-oriented choice with recurring charges. Private
# endpoint networking needs a suitable Premium design, not just a public-access toggle.
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

# Purpose: Provide a durable orders work queue for competing application consumers.
# Creation: Add the queue to the new namespace with a seven-day default message TTL,
# a 30-second processing lock, duplicate detection and a maximum delivery count of 5.
# Expired messages are dead-lettered; repeatedly unsuccessful processing also requires
# dead-letter handling. Azure brokers messages after Terraform creates this metadata.
# Important: Consumers must complete/abandon/renew locks correctly and use idempotent
# processing. Duplicate detection depends on sender message IDs; it is not a blanket
# exactly-once guarantee, and no sender or consumer application is deployed here.
resource "azurerm_servicebus_queue" "this" {
  name                                 = "orders"
  namespace_id                         = azurerm_servicebus_namespace.this.id
  default_message_ttl                  = "P7D"
  lock_duration                        = "PT30S"
  max_delivery_count                   = 5
  dead_lettering_on_message_expiration = true
  requires_duplicate_detection         = true
}

# Purpose: Create a publish/subscribe channel for business-event fan-out.
# Creation: Add business-events beneath the namespace with a seven-day default TTL.
# Consumers receive through subscriptions such as audit below, rather than reading
# directly from this topic as though it were the separate orders work queue.
# Important: This creates no publisher and grants no send/receive permission; those
# applications and their scoped identities must be configured separately.
resource "azurerm_servicebus_topic" "this" {
  name                = "business-events"
  namespace_id        = azurerm_servicebus_namespace.this.id
  default_message_ttl = "P7D"
}

# Purpose: Give the audit consumer its own delivery stream from the business-events topic.
# Creation: Reference the topic ID and create an audit subscription with delivery
# retry/dead-letter settings. The topic reference orders subscription creation.
# Important: A broker subscription is not an Azure billing subscription or an Entra
# identity. Configure consumers, authorization and dead-letter inspection; this
# block does not run an auditing application or attach custom message filters.
resource "azurerm_servicebus_subscription" "this" {
  name                                 = "audit"
  topic_id                             = azurerm_servicebus_topic.this.id
  max_delivery_count                   = 5
  dead_lettering_on_message_expiration = true
}