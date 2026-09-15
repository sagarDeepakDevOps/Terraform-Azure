# Purpose: Generate a local per-state suffix for global lake/factory/workspace names.
# Creation: Random returns three bytes as six hex characters, retained in state.
# Important: This does not create an Azure resource or recover a previous state's names.
resource "random_id" "suffix" {
  byte_length = 3
}

# Purpose: Generate a demo SQL administrator password for the optional Synapse workspace.
# Creation: Random generates 24 characters locally using the allowed special-character
# set. The value exists in state even when the workspace flag is off; no Azure charge
# is caused by this local resource. Synapse consumes it only when enabled.
# Important: Sensitive values still reside in state and require secure handling/rotation.
resource "random_password" "synapse" {
  length           = 24
  special          = true
  override_special = "!@#%_-+="
}

# Purpose: Build service names and a plan-time-known map of private service connections.
# Evaluation: Always include lake Blob/DFS and Data Factory; merge Synapse SQL,
# SqlOnDemand and Dev entries only when the workspace is selected. Each entry
# pairs its target ID/group with the exact service DNS zone name.
# Important: toset deduplicates zones: SQL and SqlOnDemand share one private DNS zone
# even though they need separate endpoint service groups. These locals create no resources.
locals {
  name = "${var.prefix}${random_id.suffix.hex}"
  private_services = merge({
    blob = { id = module.lake.id, group = "blob", zone = "privatelink.blob.core.windows.net" }
    dfs  = { id = module.lake.id, group = "dfs", zone = "privatelink.dfs.core.windows.net" }
    adf  = { id = module.factory.id, group = "dataFactory", zone = "privatelink.datafactory.azure.net" }
    }, var.enable_synapse ? {
    sql        = { id = module.synapse[0].id, group = "Sql", zone = "privatelink.sql.azuresynapse.net" }
    serverless = { id = module.synapse[0].id, group = "SqlOnDemand", zone = "privatelink.sql.azuresynapse.net" }
    dev        = { id = module.synapse[0].id, group = "Dev", zone = "privatelink.dev.azuresynapse.net" }
  } : {})
  private_zones = toset([for service in values(local.private_services) : service.zone])
}

# Purpose: Own this analytics lab separately from the other example states.
# Creation: Create the tagged group and pass its output name to platform modules.
module "resource_group" {
  source   = "../../Modules/ResourceGroups"
  name     = "${var.prefix}-rg"
  location = var.location
  tags     = var.tags
}

# Purpose: Separate ordinary private endpoints from Databricks host/container networking.
# Creation: Build 10.100.0.0/16 with one endpoint subnet and two subnets delegated
# to Microsoft.Databricks/workspaces with the required delegation actions.
# Important: This reserves topology only; Databricks/NAT/NSG resources remain opt-in,
# and a runner still needs an explicit route/DNS path to private service endpoints.
module "network" {
  source              = "../../Modules/Vnet"
  name                = "${var.prefix}-vnet"
  resource_group_name = module.resource_group.name
  location            = var.location
  address_space       = ["10.100.0.0/16"]
  subnets = {
    endpoints = { address_prefixes = ["10.100.1.0/24"] }
    dbhost = {
      address_prefixes = ["10.100.2.0/24"]
      delegation = {
        name    = "databricks", service_name = "Microsoft.Databricks/workspaces"
        actions = ["Microsoft.Network/virtualNetworks/subnets/join/action", "Microsoft.Network/virtualNetworks/subnets/prepareNetworkPolicies/action", "Microsoft.Network/virtualNetworks/subnets/unprepareNetworkPolicies/action"]
      }
    }
    dbcontainer = {
      address_prefixes = ["10.100.3.0/24"]
      delegation = {
        name    = "databricks", service_name = "Microsoft.Databricks/workspaces"
        actions = ["Microsoft.Network/virtualNetworks/subnets/join/action", "Microsoft.Network/virtualNetworks/subnets/prepareNetworkPolicies/action", "Microsoft.Network/virtualNetworks/subnets/unprepareNetworkPolicies/action"]
      }
    }
  }
  tags = var.tags
}

# Purpose: Create the ADLS Gen2 account used by the demonstration analytics platforms.
# Creation: Enable HNS in Storage and create raw, curated and synapse filesystem roots.
# Blob versioning is disabled by the module for this HNS-compatible configuration.
# Important: The filesystems are empty; identity grants and approved private paths
# are still required before data movement or queries can use them.
module "lake" {
  source                         = "../../Modules/Storage"
  name                           = "${local.name}lake"
  resource_group_name            = module.resource_group.name
  location                       = var.location
  hierarchical_namespace_enabled = true
  containers                     = ["raw", "curated", "synapse"]
  tags                           = var.tags
}

# Purpose: Provision Data Factory orchestration with an identity-backed lake connection.
# Creation: Pass the actual lake ARM ID and DFS URL; the child module creates the
# factory, managed runtime/endpoints, role grant, linked service and Wait pipeline.
# Important: Approve its managed endpoint requests on Storage before data access.
# The demonstration pipeline does not ingest real data or run on a schedule.
module "factory" {
  source               = "../../Modules/Analytics/DataFactory"
  name                 = "${local.name}-adf"
  resource_group_name  = module.resource_group.name
  location             = var.location
  storage_account_id   = module.lake.id
  storage_dfs_endpoint = module.lake.dfs_endpoint
  tags                 = var.tags
}

# Purpose: Optionally create a private Synapse workspace without dedicated compute pools.
# Creation: Use the lake's DFS endpoint plus synapse filesystem name, its ARM ID
# for permissions, and the generated password. depends_on waits for all lake children,
# including the filesystem, rather than only the account's already-known endpoint.
# Important: SQL/Spark workloads, client access and the second-stage managed endpoints
# below need separate setup; this flag is not a complete analytics runtime deployment.
module "synapse" {
  source                 = "../../Modules/Analytics/Synapse"
  count                  = var.enable_synapse ? 1 : 0
  name                   = "${local.name}-syn"
  resource_group_name    = module.resource_group.name
  location               = var.location
  storage_account_id     = module.lake.id
  filesystem_id          = "${module.lake.dfs_endpoint}synapse"
  administrator_password = random_password.synapse.result
  tags                   = var.tags

  depends_on = [module.lake]
}

# Purpose: Create one linked DNS zone per unique service namespace in the selected graph.
# Creation: for_each iterates the deduplicated zone-name set and links the analytics VNet.
# Endpoint modules retrieve zones by name, allowing SQL/SqlOnDemand to share one zone.
module "private_dns" {
  source              = "../../Modules/Vnet/PrivateDNS"
  for_each            = local.private_zones
  name                = each.value
  resource_group_name = module.resource_group.name
  virtual_network_ids = { analytics = module.network.id }
  tags                = var.tags
}

# Purpose: Expose selected lake/factory/Synapse service groups to private VNet clients.
# Creation: for_each combines each service ID/group, endpoint subnet and matching
# zone ID from private_dns. The references order endpoint creation after its target.
# Important: These are inbound client endpoints, distinct from managed outbound
# endpoints inside Data Factory or Synapse's service-managed networks.
module "private_endpoints" {
  source               = "../../Modules/Vnet/PrivateEndpoints"
  for_each             = local.private_services
  name                 = "${var.prefix}-${each.key}-pe"
  resource_group_name  = module.resource_group.name
  location             = var.location
  subnet_id            = module.network.subnet_ids["endpoints"]
  resource_id          = each.value.id
  subresource_names    = [each.value.group]
  private_dns_zone_ids = [module.private_dns[each.value.zone].id]
  tags                 = var.tags
}

# Purpose: Configure Synapse managed-VNet outbound access to the lake's Blob and DFS APIs.
# Creation: The second-stage flag expands into two managed endpoint requests, or an
# empty set when false. AzureRM uses Synapse's service data-plane API, references the
# existing workspace/lake IDs and waits for this root's client endpoints to exist.
# Important: Enable only after the runner can route to and resolve the private Dev
# endpoint. depends_on does not create that runner network path. Storage owners must
# approve the requests before data access works; role grants are also required.
resource "azurerm_synapse_managed_private_endpoint" "lake" {
  for_each             = var.configure_synapse_managed_endpoints ? toset(["blob", "dfs"]) : toset([])
  name                 = "lake-${each.key}"
  synapse_workspace_id = module.synapse[0].id
  target_resource_id   = module.lake.id
  subresource_name     = each.key

  depends_on = [module.private_endpoints]
}

# Purpose: Create and associate the NSG required for optional Databricks VNet injection.
# Creation: count follows enable_databricks and binds both delegated subnet IDs.
# Important: Databricks receives the association IDs, not just an NSG resource ID;
# required platform rules and subnet delegation must remain compatible.
module "databricks_nsg" {
  source              = "../../Modules/Vnet/NSG"
  count               = var.enable_databricks ? 1 : 0
  name                = "${var.prefix}-db-nsg"
  resource_group_name = module.resource_group.name
  location            = var.location
  subnet_ids = {
    dbhost      = module.network.subnet_ids["dbhost"]
    dbcontainer = module.network.subnet_ids["dbcontainer"]
  }
  tags = var.tags
}

# Purpose: Supply explicit egress to future private Databricks cluster nodes.
# Creation: When Databricks is selected, attach NAT to both delegated subnets before
# the workspace module proceeds. No public node IPs are required for this egress path.
# Important: NAT is billable even though this lab does not create a compute cluster.
module "databricks_nat" {
  source              = "../../Modules/Vnet/NATGateway"
  count               = var.enable_databricks ? 1 : 0
  name                = "${var.prefix}-db-nat"
  resource_group_name = module.resource_group.name
  location            = var.location
  subnet_ids = {
    dbhost      = module.network.subnet_ids["dbhost"]
    dbcontainer = module.network.subnet_ids["dbcontainer"]
  }
  tags = var.tags
}

# Purpose: Optionally create the Databricks workspace and identity-based lake connector.
# Creation: Pass the VNet, exact subnet names, NSG association outputs and lake ID;
# depends_on also waits for NAT. The child creates workspace/connector and lake grant.
# Important: The workspace UI remains authenticated public ingress while future
# classic cluster nodes have no public IP. Configure clusters, Unity Catalog storage
# credentials/external locations and real data processing in a separate deployment.
module "databricks" {
  source                     = "../../Modules/Analytics/Databricks"
  count                      = var.enable_databricks ? 1 : 0
  name                       = "${local.name}-db"
  resource_group_name        = module.resource_group.name
  location                   = var.location
  virtual_network_id         = module.network.id
  public_subnet_name         = "dbhost"
  private_subnet_name        = "dbcontainer"
  public_nsg_association_id  = module.databricks_nsg[0].association_ids["dbhost"]
  private_nsg_association_id = module.databricks_nsg[0].association_ids["dbcontainer"]
  storage_account_id         = module.lake.id
  tags                       = var.tags

  depends_on = [module.databricks_nat]
}