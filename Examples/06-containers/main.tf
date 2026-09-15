# Purpose: Read the root AzureRM tenant context for optional AKS Entra integration.
# Evaluation: This data source creates nothing; mocked tests substitute a fixture tenant ID.
data "azurerm_client_config" "current" {}

# Purpose: Generate the state-stable random component of the global ACR name.
# Creation: Random generates three bytes locally; its hex output is reused in the
# registry name. It is not an Azure resource and does not eliminate naming/quota checks.
resource "random_id" "suffix" {
  byte_length = 3
}

# Purpose: Own this independent container-platform lab and its shared dependencies.
# Creation: Create one tagged resource group before modules consuming its output name.
module "resource_group" {
  source   = "../../Modules/ResourceGroups"
  name     = "${var.prefix}-rg"
  location = var.location
  tags     = var.tags
}

# Purpose: Give Container Apps and optional AKS separate, correctly configured subnets.
# Creation: Build 10.70.0.0/16 with a non-delegated AKS node subnet and a distinct
# Microsoft.App/environments-delegated Container Apps subnet. Export their stable IDs.
# Important: No implicit egress is assumed; the NAT module serves both subnets.
module "network" {
  source              = "../../Modules/Vnet"
  name                = "${var.prefix}-vnet"
  resource_group_name = module.resource_group.name
  location            = var.location
  address_space       = ["10.70.0.0/16"]
  subnets = {
    aks = { address_prefixes = ["10.70.0.0/22"] }
    apps = {
      address_prefixes = ["10.70.4.0/23"]
      delegation       = { name = "apps", service_name = "Microsoft.App/environments" }
    }
  }
  tags = var.tags
}

# Purpose: Provide explicit egress for Container Apps and optional AKS node bootstrap.
# Creation: Pass the network's named subnet-ID map into NATGateway so both associations
# are completed before dependent container-platform modules begin provisioning.
module "nat" {
  source              = "../../Modules/Vnet/NATGateway"
  name                = "${var.prefix}-nat"
  resource_group_name = module.resource_group.name
  location            = var.location
  subnet_ids          = module.network.subnet_ids
  tags                = var.tags
}

# Purpose: Create the workspace used by Container Apps logging and optional AKS monitoring.
# Creation: Provision LogAnalytics in the lab group; platform modules consume its ARM ID.
# Important: Workspace quotas/retention affect telemetry, and ingestion is billable.
module "logs" {
  source              = "../../Modules/Monitoring/LogAnalytics"
  name                = "${var.prefix}-logs"
  resource_group_name = module.resource_group.name
  location            = var.location
  tags                = var.tags
}

# Purpose: Create the image registry used for future private application image releases.
# Creation: Combine the prefix/random suffix into a global name and create Basic ACR.
# Important: Shared admin credentials are disabled, but Basic's endpoint is public
# with authentication. No build or image upload is performed by this call.
module "registry" {
  source              = "../../Modules/ContainerRegistry"
  name                = "${var.prefix}${random_id.suffix.hex}acr"
  resource_group_name = module.resource_group.name
  location            = var.location
  tags                = var.tags
}

# Purpose: Give Container Apps a reusable identity for registry image pulls.
# Creation: Create the identity after the group, then use its principal ID for the
# registry grant and its ARM ID for attachment to the Container App.
module "app_identity" {
  source              = "../../Modules/Identity"
  name                = "${var.prefix}-app-identity"
  resource_group_name = module.resource_group.name
  location            = var.location
  tags                = var.tags
}

# Purpose: Allow the Container App identity to pull, but not push, ACR images.
# Creation: Grant AcrPull on the created registry to the created identity principal.
# Important: Azure role propagation can delay first use; no registry password is created.
module "app_roles" {
  source = "../../Modules/RoleAssignments"
  assignments = {
    pull = { scope = module.registry.id, role = "AcrPull", principal_id = module.app_identity.principal_id }
  }
}

# Purpose: Deploy a runnable sample Container App with HTTPS, probes and HTTP scaling.
# Creation: Pass the environment subnet, workspace, identity and registry hostname;
# wait for both the registry role and NAT. The module's default image is public, so
# the initial demo works without first populating the new ACR.
# Important: Production must select a reviewed image and application authentication.
module "apps" {
  source                     = "../../Modules/ContainerApps"
  name                       = "${var.prefix}-app"
  resource_group_name        = module.resource_group.name
  location                   = var.location
  subnet_id                  = module.network.subnet_ids["apps"]
  log_analytics_workspace_id = module.logs.id
  identity_id                = module.app_identity.id
  registry_server            = module.registry.login_server
  tags                       = var.tags

  depends_on = [module.app_roles, module.nat]
}

# Purpose: Create a separate control-plane identity only when AKS is selected.
# Creation: count follows enable_aks; the AKS module later receives its ARM/principal IDs.
# Important: The child AKS module creates a distinct kubelet identity for image pulls.
module "aks_identity" {
  source              = "../../Modules/Identity"
  count               = var.enable_aks ? 1 : 0
  name                = "${var.prefix}-aks-identity"
  resource_group_name = module.resource_group.name
  location            = var.location
  tags                = var.tags
}

# Purpose: Let the optional AKS control plane manage its network/private DNS linkage.
# Creation: Grant Network Contributor to its identity at VNet scope before cluster
# creation. Subnet-only scope would miss permissions needed to link the private DNS zone.
# Important: This is an Azure infrastructure permission, not Kubernetes administrator access.
module "aks_network_role" {
  source = "../../Modules/RoleAssignments"
  count  = var.enable_aks ? 1 : 0
  assignments = {
    network = {
      scope = module.network.id, role = "Network Contributor", principal_id = module.aks_identity[0].principal_id
    }
  }
}

# Purpose: Optionally add private Kubernetes alongside the Container Apps example.
# Creation: count follows enable_aks and passes node subnet, both control-plane
# identity IDs, tenant/admin groups, workspace and registry into the AKS module.
# depends_on waits for the VNet role and NAT; child dependencies handle kubelet grants.
# Important: Admin group IDs must already exist. Nodes/networking are paid, workloads
# are not deployed, and kubectl requires private DNS/routing plus Entra authorization.
module "aks" {
  source                     = "../../Modules/AKS"
  count                      = var.enable_aks ? 1 : 0
  name                       = "${var.prefix}-aks"
  resource_group_name        = module.resource_group.name
  location                   = var.location
  subnet_id                  = module.network.subnet_ids["aks"]
  identity_id                = module.aks_identity[0].id
  identity_principal_id      = module.aks_identity[0].principal_id
  tenant_id                  = data.azurerm_client_config.current.tenant_id
  admin_group_object_ids     = var.aks_admin_group_object_ids
  log_analytics_workspace_id = module.logs.id
  registry_id                = module.registry.id
  tags                       = var.tags

  depends_on = [module.aks_network_role, module.nat]
}