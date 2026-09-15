resource "random_id" "suffix" {
  byte_length = 3
}

locals {
  name = "${var.prefix}${random_id.suffix.hex}"
}

module "resource_group" {
  source   = "../../Modules/ResourceGroups"
  name     = "${var.prefix}-rg"
  location = var.location
  tags     = var.tags
}

module "service_bus" {
  source              = "../../Modules/Messaging/ServiceBus"
  name                = "${local.name}-sb"
  resource_group_name = module.resource_group.name
  location            = var.location
  tags                = var.tags
}

module "event_hubs" {
  source              = "../../Modules/Messaging/EventHubs"
  name                = "${local.name}-eh"
  resource_group_name = module.resource_group.name
  location            = var.location
  tags                = var.tags
}

module "storage" {
  source              = "../../Modules/Storage"
  name                = "${local.name}st"
  resource_group_name = module.resource_group.name
  location            = var.location
  containers          = ["incoming"]
  tags                = var.tags
}

module "network" {
  source              = "../../Modules/Vnet"
  name                = "${var.prefix}-vnet"
  resource_group_name = module.resource_group.name
  location            = var.location
  address_space       = ["10.90.0.0/16"]
  subnets = {
    endpoints = { address_prefixes = ["10.90.1.0/24"] }
  }
  tags = var.tags
}

module "storage_dns" {
  source              = "../../Modules/Vnet/PrivateDNS"
  name                = "privatelink.blob.core.windows.net"
  resource_group_name = module.resource_group.name
  virtual_network_ids = { integration = module.network.id }
  tags                = var.tags
}

module "storage_endpoint" {
  source               = "../../Modules/Vnet/PrivateEndpoints"
  name                 = "${var.prefix}-blob-pe"
  resource_group_name  = module.resource_group.name
  location             = var.location
  subnet_id            = module.network.subnet_ids["endpoints"]
  resource_id          = module.storage.id
  subresource_names    = ["blob"]
  private_dns_zone_ids = [module.storage_dns.id]
  tags                 = var.tags
}

module "event_grid" {
  source               = "../../Modules/Messaging/EventGrid"
  name                 = "${var.prefix}-storage-events"
  resource_group_name  = module.resource_group.name
  location             = var.location
  storage_account_id   = module.storage.id
  service_bus_queue_id = module.service_bus.queue_id
  tags                 = var.tags
}

module "workflow" {
  source              = "../../Modules/LogicApps"
  name                = "${var.prefix}-workflow"
  resource_group_name = module.resource_group.name
  location            = var.location
  enabled             = var.enable_workflow
  tags                = var.tags
}

module "identity" {
  source              = "../../Modules/Identity"
  name                = "${var.prefix}-consumer"
  resource_group_name = module.resource_group.name
  location            = var.location
  tags                = var.tags
}

module "roles" {
  source = "../../Modules/RoleAssignments"
  assignments = {
    service_bus = {
      scope = module.service_bus.queue_id, role = "Azure Service Bus Data Receiver", principal_id = module.identity.principal_id
    }
    event_hub = {
      scope = module.event_hubs.eventhub_id, role = "Azure Event Hubs Data Receiver", principal_id = module.identity.principal_id
    }
  }
}

module "api_management" {
  source              = "../../Modules/APIManagement"
  count               = var.enable_api_management ? 1 : 0
  name                = "${local.name}-apim"
  resource_group_name = module.resource_group.name
  location            = var.location
  publisher_email     = var.publisher_email
  tags                = var.tags
}