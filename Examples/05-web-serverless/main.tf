# Purpose: Generate a local, state-stable suffix for globally unique hosting/storage names.
# Creation: Random produces three bytes and exposes six hex characters; no Azure
# service is created by this value and a fresh state produces a different suffix.
resource "random_id" "suffix" {
  byte_length = 3
}

# Purpose: Reuse the caller's prefix plus the generated suffix across hosting resources.
# Evaluation: This local is a Terraform expression, not an independently created resource.
locals {
  name = "${var.prefix}${random_id.suffix.hex}"
}

# Purpose: Isolate all web/serverless dependencies in this lab's own resource group.
# Creation: Create the group once; subsequent module references order child creation.
module "resource_group" {
  source   = "../../Modules/ResourceGroups"
  name     = "${var.prefix}-rg"
  location = var.location
  tags     = var.tags
}

# Purpose: Separate Web App integration, Flex Functions integration and private endpoints.
# Creation: Build three subnets in 10.60.0.0/16 with service-specific delegations:
# Web uses serverFarms, Flex uses Microsoft.App/environments, endpoints stay undelegated.
# Important: VNet integration is outbound access; it does not make web ingress private.
module "network" {
  source              = "../../Modules/Vnet"
  name                = "${var.prefix}-vnet"
  resource_group_name = module.resource_group.name
  location            = var.location
  address_space       = ["10.60.0.0/16"]
  subnets = {
    web = {
      address_prefixes = ["10.60.1.0/24"]
      delegation       = { name = "web", service_name = "Microsoft.Web/serverFarms" }
    }
    functions = {
      address_prefixes = ["10.60.2.0/24"]
      delegation       = { name = "flex", service_name = "Microsoft.App/environments" }
    }
    endpoints = { address_prefixes = ["10.60.3.0/24"] }
  }
  tags = var.tags
}

# Purpose: Supply explicit outbound Internet access to the two integration subnets.
# Creation: Attach one NAT gateway/public IP to the created web and functions subnet IDs.
# Web/Function modules wait for the whole module so route-all traffic has an egress path.
module "nat" {
  source              = "../../Modules/Vnet/NATGateway"
  name                = "${var.prefix}-nat"
  resource_group_name = module.resource_group.name
  location            = var.location
  subnet_ids = {
    web       = module.network.subnet_ids["web"]
    functions = module.network.subnet_ids["functions"]
  }
  tags = var.tags
}

# Purpose: Create the workspace storing this lab's application telemetry.
# Creation: Pass the new group name into LogAnalytics; Insights consumes its ARM ID.
# Important: Ingestion is billable and application instrumentation remains necessary.
module "logs" {
  source              = "../../Modules/Monitoring/LogAnalytics"
  name                = "${var.prefix}-logs"
  resource_group_name = module.resource_group.name
  location            = var.location
  tags                = var.tags
}

# Purpose: Create workspace-backed Application Insights configuration for web and Functions.
# Creation: The workspace ID orders component creation; its connection string is
# supplied to the hosting modules, rather than hardcoded in application configuration.
module "insights" {
  source              = "../../Modules/Monitoring/ApplicationInsights"
  name                = "${var.prefix}-insights"
  resource_group_name = module.resource_group.name
  location            = var.location
  workspace_id        = module.logs.id
  tags                = var.tags
}

# Purpose: Provision HTTPS Node hosting with outbound VNet access and telemetry settings.
# Creation: Pass the web subnet and Insights connection string to AppService, which
# creates the plan/site after those resources; depends_on also waits for NAT.
# Important: This provisions hosting only. Application code, authentication and
# useful telemetry must be deployed/verified separately.
module "web" {
  source                = "../../Modules/AppService"
  name                  = "${local.name}-app"
  resource_group_name   = module.resource_group.name
  location              = var.location
  integration_subnet_id = module.network.subnet_ids["web"]
  app_settings = {
    APPLICATIONINSIGHTS_CONNECTION_STRING = module.insights.connection_string
  }
  tags = var.tags

  depends_on = [module.nat]
}

# Purpose: Provide private host/deployment storage for the Flex Function App.
# Creation: The Storage module creates the named account and deployments blob container.
# Shared keys remain disabled; the identity roles and endpoint modules below make
# authorized private storage access possible for the Function runtime.
module "storage" {
  source              = "../../Modules/Storage"
  name                = "${local.name}func"
  resource_group_name = module.resource_group.name
  location            = var.location
  containers          = ["deployments"]
  tags                = var.tags
}

# Purpose: Resolve the host storage's Blob, Queue and Table endpoints privately.
# Creation: for_each creates the exact service zone for each key and links the lab VNet.
# The endpoint loop below uses matching keys to retrieve the right DNS zone ID.
module "storage_dns" {
  source              = "../../Modules/Vnet/PrivateDNS"
  for_each            = toset(["blob", "queue", "table"])
  name                = "privatelink.${each.key}.core.windows.net"
  resource_group_name = module.resource_group.name
  virtual_network_ids = { web = module.network.id }
  tags                = var.tags
}

# Purpose: Build all three private service connections needed by the host storage design.
# Creation: Each stable service key maps to its storage subresource, newly linked
# DNS zone and the endpoint subnet; the shared account ID orders target creation.
# Important: Private endpoints do not grant storage access; the identity grants below do.
module "storage_endpoints" {
  source               = "../../Modules/Vnet/PrivateEndpoints"
  for_each             = toset(["blob", "queue", "table"])
  name                 = "${var.prefix}-${each.key}-pe"
  resource_group_name  = module.resource_group.name
  location             = var.location
  subnet_id            = module.network.subnet_ids["endpoints"]
  resource_id          = module.storage.id
  subresource_names    = [each.key]
  private_dns_zone_ids = [module.storage_dns[each.key].id]
  tags                 = var.tags
}

# Purpose: Create the user-assigned identity shared by Function host and deployment storage.
# Creation: Its ARM ID attaches to the Function App and its client ID selects that
# identity at runtime; the separate principal ID is used for RBAC assignments below.
module "identity" {
  source              = "../../Modules/Identity"
  name                = "${var.prefix}-functions-identity"
  resource_group_name = module.resource_group.name
  location            = var.location
  tags                = var.tags
}

# Purpose: Authorize identity-based Function host/deployment storage without account keys.
# Creation: Grant the listed Blob/Queue/Table data roles plus storage management
# rights to the Function identity at this dedicated account's scope. The Function
# module waits for these grants, but Azure propagation can still delay initial access.
# Important: These are not subscription-wide grants or application business-data roles.
module "function_roles" {
  source = "../../Modules/RoleAssignments"
  assignments = {
    blob = {
      scope = module.storage.id, role = "Storage Blob Data Owner", principal_id = module.identity.principal_id
    }
    queue = {
      scope = module.storage.id, role = "Storage Queue Data Contributor", principal_id = module.identity.principal_id
    }
    table = {
      scope = module.storage.id, role = "Storage Table Data Contributor", principal_id = module.identity.principal_id
    }
    storage = {
      scope = module.storage.id, role = "Storage Account Contributor", principal_id = module.identity.principal_id
    }
  }
}

# Purpose: Create the Flex Function App after its private storage prerequisites exist.
# Creation: Pass the deployment-container URL, host-account name, identity ARM/client
# IDs, integration subnet and Insights setting. Explicit dependencies wait for role
# assignments, all three endpoints and NAT, not just individual resource IDs.
# Important: This deploys no Function package. Publish compatible code and verify
# host startup, authorization and invocation separately; the endpoint remains HTTPS ingress.
module "functions" {
  source                                 = "../../Modules/Functions"
  name                                   = "${local.name}-func"
  resource_group_name                    = module.resource_group.name
  location                               = var.location
  storage_account_name                   = module.storage.name
  storage_container_endpoint             = "${module.storage.blob_endpoint}deployments"
  identity_id                            = module.identity.id
  identity_client_id                     = module.identity.client_id
  integration_subnet_id                  = module.network.subnet_ids["functions"]
  application_insights_connection_string = module.insights.connection_string
  tags                                   = var.tags

  depends_on = [module.function_roles, module.storage_endpoints, module.nat]
}