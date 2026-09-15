# Purpose: Generate a stable per-state suffix for global messaging/storage names.
# Creation: Random creates a local three-byte value; services use its hex output.
# Important: No Azure service is created here and the suffix is not a secret credential.
resource "random_id" "suffix" {
  byte_length = 3
}

# Purpose: Reuse the configured prefix and random suffix across integration service names.
# Evaluation: This expression is computed by Terraform and creates no Azure resource.
locals {
  name = "${var.prefix}${random_id.suffix.hex}"
}

# Purpose: Isolate the messaging, workflow and API demonstration from other labs.
# Creation: All service modules use the output name of this newly created group.
module "resource_group" {
  source   = "../../Modules/ResourceGroups"
  name     = "${var.prefix}-rg"
  location = var.location
  tags     = var.tags
}

# Purpose: Create the orders queue plus a separate business-events topic/audit subscription.
# Creation: The ServiceBus module creates the Standard namespace and child broker objects.
# Its queue ID becomes the Event Grid destination and receiver-role scope below.
# Important: Entra authentication is required; no producer or consumer program is started.
module "service_bus" {
  source              = "../../Modules/Messaging/ServiceBus"
  name                = "${local.name}-sb"
  resource_group_name = module.resource_group.name
  location            = var.location
  tags                = var.tags
}

# Purpose: Provide a separate partitioned telemetry-streaming example.
# Creation: Create the namespace, telemetry event hub and analytics consumer group;
# its stream ID is used for the consumer identity's receive permission below.
# Important: It is not automatically fed by the Blob-to-Service-Bus event path.
module "event_hubs" {
  source              = "../../Modules/Messaging/EventHubs"
  name                = "${local.name}-eh"
  resource_group_name = module.resource_group.name
  location            = var.location
  tags                = var.tags
}

# Purpose: Create the private incoming blob container whose writes generate source events.
# Creation: Build a key-disabled StorageV2 account/container after the group exists.
# Important: No blob is uploaded during apply. An authorized private-network uploader
# must create sample data to exercise the later BlobCreated notification path.
module "storage" {
  source              = "../../Modules/Storage"
  name                = "${local.name}st"
  resource_group_name = module.resource_group.name
  location            = var.location
  containers          = ["incoming"]
  tags                = var.tags
}

# Purpose: Host a private endpoint for source storage within this independent lab.
# Creation: Build 10.90.0.0/16 and its endpoint subnet, exporting the ID used below.
# Important: This does not create a VPN or connect an operator's workstation automatically.
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

# Purpose: Resolve the storage Blob endpoint privately from the integration VNet.
# Creation: Create the Blob private DNS zone and explicitly link the new VNet ID.
# The private endpoint references this zone after both network and zone exist.
module "storage_dns" {
  source              = "../../Modules/Vnet/PrivateDNS"
  name                = "privatelink.blob.core.windows.net"
  resource_group_name = module.resource_group.name
  virtual_network_ids = { integration = module.network.id }
  tags                = var.tags
}

# Purpose: Give authorized source-blob clients a private path into the storage account.
# Creation: Join the account's blob group, endpoint subnet and linked DNS zone IDs.
# Important: Storage data roles are still required; the messaging receiver roles below
# do not automatically allow an operator or application to upload blobs.
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

# Purpose: Wire Storage BlobCreated notifications into the actual orders queue.
# Creation: Pass the source account and Service Bus queue IDs; the child module
# creates its system topic/identity, grants queue-send permission and attaches the filter.
# Important: It delivers event metadata, not blob contents, and consumers must handle duplicates.
module "event_grid" {
  source               = "../../Modules/Messaging/EventGrid"
  name                 = "${var.prefix}-storage-events"
  resource_group_name  = module.resource_group.name
  location             = var.location
  storage_account_id   = module.storage.id
  service_bus_queue_id = module.service_bus.queue_id
  tags                 = var.tags
}

# Purpose: Demonstrate a complete daily Logic App with a simple Compose action.
# Creation: The module creates the workflow/trigger/action using enable_workflow,
# which is false by default to avoid unattended scheduled executions and their costs.
# Important: This workflow is independent of the queue/stream and contains no external connectors.
module "workflow" {
  source              = "../../Modules/LogicApps"
  name                = "${var.prefix}-workflow"
  resource_group_name = module.resource_group.name
  location            = var.location
  enabled             = var.enable_workflow
  tags                = var.tags
}

# Purpose: Create an identity a future consumer application can attach and use.
# Creation: Its principal ID receives scoped queue/stream roles below; its ARM ID
# would be attached to the consuming workload, which is not provisioned in this lab.
module "identity" {
  source              = "../../Modules/Identity"
  name                = "${var.prefix}-consumer"
  resource_group_name = module.resource_group.name
  location            = var.location
  tags                = var.tags
}

# Purpose: Give the consumer identity receive access to the orders queue and telemetry stream.
# Creation: Use the created broker IDs as scopes and the identity's principal ID
# for Service Bus/Event Hubs data-receiver grants after those resources exist.
# Important: These are receive-only data grants, not send or infrastructure-management rights.
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

# Purpose: Optionally add the protected /demo/health API gateway example.
# Creation: count follows enable_api_management and passes the required publisher
# contact into the Developer APIM module, which creates API/operation/product/policy resources.
# Important: It has recurring cost and slow provisioning. An APIM subscription must
# be created/approved before using its health operation; the test fixtures are not credentials.
module "api_management" {
  source              = "../../Modules/APIManagement"
  count               = var.enable_api_management ? 1 : 0
  name                = "${local.name}-apim"
  resource_group_name = module.resource_group.name
  location            = var.location
  publisher_email     = var.publisher_email
  tags                = var.tags
}