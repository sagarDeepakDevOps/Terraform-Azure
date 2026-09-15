# Purpose: Read the root provider's tenant for the optional ML workspace's Key Vault.
# Evaluation: This lookup creates no Entra object; mocked tests supply a fake tenant ID.
data "azurerm_client_config" "current" {}

# Purpose: Generate a state-stable suffix for globally unique AI/storage service names.
# Creation: Random generates three bytes locally and exports six hexadecimal characters.
# Important: This is a naming aid, not a credential or an Azure-deployed resource.
resource "random_id" "suffix" {
  byte_length = 3
}

# Purpose: Derive names and pair each selected AI service with its private endpoint groups.
# Evaluation: Always include Cognitive Services/Search; merge OpenAI and ML dependencies
# only when selected. Each service carries a list of DNS zones because ML needs both
# API and notebook namespaces for its single amlworkspace endpoint group.
# flatten collects all zone names and toset removes duplicates before zone creation.
# Important: Known map keys drive for_each even while created resource IDs are unknown;
# these expressions wire dependencies but do not grant access or create endpoints themselves.
locals {
  name = "${var.prefix}${random_id.suffix.hex}"
  private_services = merge({
    cognitive = { id = module.cognitive.id, group = "account", zones = ["privatelink.cognitiveservices.azure.com"] }
    search    = { id = module.search.id, group = "searchService", zones = ["privatelink.search.windows.net"] }
    }, var.enable_openai ? {
    openai = { id = module.openai[0].id, group = "account", zones = ["privatelink.openai.azure.com"] }
    } : {}, var.enable_machine_learning ? {
    ml    = { id = module.machine_learning[0].id, group = "amlworkspace", zones = ["privatelink.api.azureml.ms", "privatelink.notebooks.azure.net"] }
    blob  = { id = module.ml_storage[0].id, group = "blob", zones = ["privatelink.blob.core.windows.net"] }
    file  = { id = module.ml_storage[0].id, group = "file", zones = ["privatelink.file.core.windows.net"] }
    vault = { id = module.ml_vault[0].id, group = "vault", zones = ["privatelink.vaultcore.azure.net"] }
  } : {})
  private_zones = toset(flatten([for service in values(local.private_services) : service.zones]))
}

# Purpose: Keep this AI reference lab and optional ML dependencies under one independent state.
# Creation: Create the tagged resource group before modules that consume its name output.
module "resource_group" {
  source   = "../../Modules/ResourceGroups"
  name     = "${var.prefix}-rg"
  location = var.location
  tags     = var.tags
}

# Purpose: Host the private AI, storage and vault endpoints selected by this root.
# Creation: Create 10.110.0.0/16 with an undelegated endpoint subnet and export its ID.
# Important: No client VPN, private runner or ML training subnet is provisioned here.
module "network" {
  source              = "../../Modules/Vnet"
  name                = "${var.prefix}-vnet"
  resource_group_name = module.resource_group.name
  location            = var.location
  address_space       = ["10.110.0.0/16"]
  subnets = {
    endpoints = { address_prefixes = ["10.110.1.0/24"] }
  }
  tags = var.tags
}

# Purpose: Create an identity a future application can use to call the AI services.
# Creation: Its principal ID receives AI/Search roles, while a deployed application
# would attach/select its ARM/client ID. The optional ML workspace uses a different identity.
module "identity" {
  source              = "../../Modules/Identity"
  name                = "${var.prefix}-app-identity"
  resource_group_name = module.resource_group.name
  location            = var.location
  tags                = var.tags
}

# Purpose: Deploy a private multi-service AI account with local API keys disabled.
# Creation: The child module uses the global name/group/region; the private-services
# map consumes its ID and ai_roles grants the app identity permission afterward.
# Important: This does not implement an application or enable every specialized AI capability.
module "cognitive" {
  source              = "../../Modules/AI/CognitiveServices"
  name                = "${local.name}-cog"
  resource_group_name = module.resource_group.name
  location            = var.location
  tags                = var.tags
}

# Purpose: Provision private, Entra-authenticated Search capacity for later indexes.
# Creation: Create the Basic service in the new group and feed its ID into endpoint
# and role modules. Important: Index schemas/documents are not deployed; idle Search is billable.
module "search" {
  source              = "../../Modules/AI/Search"
  name                = "${local.name}-search"
  resource_group_name = module.resource_group.name
  location            = var.location
  tags                = var.tags
}

# Purpose: Optionally create an OpenAI account and only the explicitly requested models.
# Creation: count follows enable_openai and passes the deployment map to the child;
# an empty map creates an account without an inference model deployment.
# Important: Verify model/version/SKU availability, quota and residency before selecting
# deployments. The mock model fixtures are not a promise of live regional availability.
module "openai" {
  source              = "../../Modules/AI/OpenAI"
  count               = var.enable_openai ? 1 : 0
  name                = "${local.name}-openai"
  resource_group_name = module.resource_group.name
  location            = var.location
  deployments         = var.openai_deployments
  tags                = var.tags
}

# Purpose: Authorize the application identity for the selected AI service APIs.
# Creation: Merge Cognitive/Search grants with an OpenAI grant only when its account
# exists; each role uses the matching service ARM scope and the app principal ID.
# Important: Search document-data permission is not index-administration permission,
# and none of these roles establishes a network path or attaches an application.
module "ai_roles" {
  source = "../../Modules/RoleAssignments"
  assignments = merge({
    cognitive = { scope = module.cognitive.id, role = "Cognitive Services User", principal_id = module.identity.principal_id }
    search    = { scope = module.search.id, role = "Search Index Data Contributor", principal_id = module.identity.principal_id }
    }, var.enable_openai ? {
    openai = { scope = module.openai[0].id, role = "Cognitive Services OpenAI User", principal_id = module.identity.principal_id }
  } : {})
}

# Purpose: Provision dedicated system/artifact storage only when the ML workspace is selected.
# Creation: count follows enable_machine_learning and creates non-HNS private Storage
# with empty datasets/artifacts containers. Its ID is reused for workspace access/roles.
# Important: This does not upload datasets or create training jobs; shared keys stay disabled.
module "ml_storage" {
  source              = "../../Modules/Storage"
  count               = var.enable_machine_learning ? 1 : 0
  name                = "${local.name}ml"
  resource_group_name = module.resource_group.name
  location            = var.location
  containers          = ["datasets", "artifacts"]
  tags                = var.tags
}

# Purpose: Create the ML workspace's dedicated private vault and retention boundary.
# Creation: When ML is enabled, pass the current tenant and generated vault name.
# Important: The workspace identity receives separate data/management grants below;
# no secrets are seeded, and purge protection affects later deletion/name reuse.
module "ml_vault" {
  source              = "../../Modules/KeyVault"
  count               = var.enable_machine_learning ? 1 : 0
  name                = "${local.name}-mlkv"
  resource_group_name = module.resource_group.name
  location            = var.location
  tenant_id           = data.azurerm_client_config.current.tenant_id
  tags                = var.tags
}

# Purpose: Create the optional ML telemetry workspace only with the ML feature.
# Creation: Its ARM ID becomes the backing workspace for ml_insights below.
# Important: Actual workload telemetry and ingestion costs depend on later ML activity.
module "ml_logs" {
  source              = "../../Modules/Monitoring/LogAnalytics"
  count               = var.enable_machine_learning ? 1 : 0
  name                = "${var.prefix}-ml-logs"
  resource_group_name = module.resource_group.name
  location            = var.location
  tags                = var.tags
}

# Purpose: Supply the Application Insights dependency required by the ML workspace.
# Creation: Link the component to the created ML Log Analytics workspace; pass the
# resulting component ARM ID, not its connection string, to machine_learning below.
module "ml_insights" {
  source              = "../../Modules/Monitoring/ApplicationInsights"
  count               = var.enable_machine_learning ? 1 : 0
  name                = "${var.prefix}-ml-insights"
  resource_group_name = module.resource_group.name
  location            = var.location
  workspace_id        = module.ml_logs[0].id
  tags                = var.tags
}

# Purpose: Keep the ML platform identity separate from the application's AI-calling identity.
# Creation: Create one user-assigned identity when ML is enabled; its principal ID
# receives dependency access, and its ARM ID is attached as the workspace identity.
module "ml_identity" {
  source              = "../../Modules/Identity"
  count               = var.enable_machine_learning ? 1 : 0
  name                = "${var.prefix}-ml-identity"
  resource_group_name = module.resource_group.name
  location            = var.location
  tags                = var.tags
}

# Purpose: Pre-authorize the ML workspace identity on its storage, vault and telemetry.
# Creation: Expand explicit resource-scoped grants for Blob/Files data, storage
# management, vault secrets/management and monitoring using the created dependency IDs.
# Important: These are platform dependency roles, not grants to every scientist/user.
# The workspace waits for assignment creation, but Azure propagation can still delay use.
module "ml_roles" {
  source = "../../Modules/RoleAssignments"
  count  = var.enable_machine_learning ? 1 : 0
  assignments = {
    blobs    = { scope = module.ml_storage[0].id, role = "Storage Blob Data Contributor", principal_id = module.ml_identity[0].principal_id }
    files    = { scope = module.ml_storage[0].id, role = "Storage File Data Privileged Contributor", principal_id = module.ml_identity[0].principal_id }
    storage  = { scope = module.ml_storage[0].id, role = "Storage Account Contributor", principal_id = module.ml_identity[0].principal_id }
    secrets  = { scope = module.ml_vault[0].id, role = "Key Vault Secrets Officer", principal_id = module.ml_identity[0].principal_id }
    vault    = { scope = module.ml_vault[0].id, role = "Key Vault Contributor", principal_id = module.ml_identity[0].principal_id }
    insights = { scope = module.ml_insights[0].id, role = "Monitoring Contributor", principal_id = module.ml_identity[0].principal_id }
  }
}

# Purpose: Optionally create the private ML workspace with identity-based system storage.
# Creation: Pass storage, vault, Insights and identity ARM IDs after the required role
# grants. The child configures managed networking but defers its provisioning stage.
# Important: No compute, trained model or inference endpoint is created. Private
# client access and approved managed outbound connections are still required for real work.
module "machine_learning" {
  source                  = "../../Modules/AI/MachineLearning"
  count                   = var.enable_machine_learning ? 1 : 0
  name                    = "${local.name}-ml"
  resource_group_name     = module.resource_group.name
  location                = var.location
  storage_account_id      = module.ml_storage[0].id
  key_vault_id            = module.ml_vault[0].id
  application_insights_id = module.ml_insights[0].id
  identity_id             = module.ml_identity[0].id
  tags                    = var.tags

  depends_on = [module.ml_roles]
}

# Purpose: Create/link each unique private namespace needed by the selected AI graph.
# Creation: for_each uses the flattened, deduplicated zone-name set and links this
# lab's VNet. Endpoint groups below retrieve the appropriate one or more zone IDs.
# Important: Other client networks need explicit links or forwarding, not merely peering.
module "private_dns" {
  source              = "../../Modules/Vnet/PrivateDNS"
  for_each            = local.private_zones
  name                = each.value
  resource_group_name = module.resource_group.name
  virtual_network_ids = { ai = module.network.id }
  tags                = var.tags
}

# Purpose: Bind each selected AI service/dependency to the private endpoint subnet.
# Creation: Pair its ARM ID/service group with all required zone IDs and the subnet.
# The inner for expression handles the ML API/notebook multi-zone case without
# creating duplicate service endpoints solely because a service uses two DNS zones.
# Important: These inbound connections do not provision the ML managed outbound network.
module "private_endpoints" {
  source               = "../../Modules/Vnet/PrivateEndpoints"
  for_each             = local.private_services
  name                 = "${var.prefix}-${each.key}-pe"
  resource_group_name  = module.resource_group.name
  location             = var.location
  subnet_id            = module.network.subnet_ids["endpoints"]
  resource_id          = each.value.id
  subresource_names    = [each.value.group]
  private_dns_zone_ids = [for zone in each.value.zones : module.private_dns[zone].id]
  tags                 = var.tags
}