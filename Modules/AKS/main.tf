terraform {
  required_version = ">= 1.9.0, < 2.0.0"
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = ">= 4.81.0, < 5.0.0"
    }
  }
}

# Purpose: Give AKS worker-node kubelets their own explicit Azure identity for image pulls.
# Creation: Azure creates this user-assigned identity before the cluster; its ARM,
# client and principal IDs populate the cluster's kubelet_identity block below.
# Important: This is distinct from the caller-supplied control-plane identity and
# from application workload identities. Its permissions are granted separately.
resource "azurerm_user_assigned_identity" "kubelet" {
  name                = "${var.name}-kubelet"
  resource_group_name = var.resource_group_name
  location            = var.location
  tags                = var.tags
}

# Purpose: Let the AKS control-plane identity assign/use the explicit kubelet identity.
# Creation: Grant Managed Identity Operator on the new kubelet identity resource
# to var.identity_principal_id, the Entra object ID of the control-plane identity.
# The cluster explicitly waits for this grant before provisioning.
# Important: This role is scoped to that identity and is not permission to pull
# registry images or administer Kubernetes; those are different grants/settings.
resource "azurerm_role_assignment" "kubelet_operator" {
  scope                = azurerm_user_assigned_identity.kubelet.id
  role_definition_name = "Managed Identity Operator"
  principal_id         = var.identity_principal_id
  principal_type       = "ServicePrincipal"
}

# Purpose: Create a private AKS platform with Entra administration and explicit identities.
# Creation: Azure provisions the managed control plane and an Ubuntu system pool
# in subnet_id, using the caller's identity for Azure management and the identity
# above for kubelets. The caller first grants Network Contributor on the VNet and
# attaches NAT; explicit depends_on also waits for identity-operator/registry grants.
# Networking: The API uses an AKS-managed private DNS zone with no public FQDN.
# Azure CNI overlay/Cilium uses separate pod/service ranges, and userAssignedNATGateway
# egress requires the caller's real NAT association. Ranges must not overlap connected
# networks. A client needs private routing/DNS plus Entra permissions to use kubectl.
# Operations: Enable patch/node-image upgrade channels, monitoring, workload-identity
# capability, Azure Policy integration and secret rotation through the Key Vault CSI
# provider. These features do not create application policies, secrets or workloads.
# Important: Free refers to the control-plane tier, not VM nodes/disks/networking.
# No Kubernetes manifests or workload federated credentials are installed by this block.
resource "azurerm_kubernetes_cluster" "this" {
  name                                = var.name
  resource_group_name                 = var.resource_group_name
  location                            = var.location
  dns_prefix                          = var.name
  kubernetes_version                  = var.kubernetes_version
  sku_tier                            = "Free"
  private_cluster_enabled             = true
  private_cluster_public_fqdn_enabled = false
  private_dns_zone_id                 = "System"
  local_account_disabled              = true
  role_based_access_control_enabled   = true
  oidc_issuer_enabled                 = true
  workload_identity_enabled           = true
  azure_policy_enabled                = true
  automatic_upgrade_channel           = "patch"
  node_os_upgrade_channel             = "NodeImage"
  tags                                = var.tags

  # Azure may autoscale the initial one-node pool between one and three nodes.
  # The rotation name and surge setting support managed node-pool updates.
  default_node_pool {
    name                        = "system"
    vm_size                     = var.node_size
    vnet_subnet_id              = var.subnet_id
    os_sku                      = "Ubuntu"
    auto_scaling_enabled        = true
    node_count                  = 1
    min_count                   = 1
    max_count                   = 3
    temporary_name_for_rotation = "sysrotate"

    upgrade_settings {
      max_surge = "33%"
    }
  }

  identity {
    type         = "UserAssigned"
    identity_ids = [var.identity_id]
  }

  kubelet_identity {
    client_id                 = azurerm_user_assigned_identity.kubelet.client_id
    object_id                 = azurerm_user_assigned_identity.kubelet.principal_id
    user_assigned_identity_id = azurerm_user_assigned_identity.kubelet.id
  }

  # Supply existing Entra group object IDs, not group names or client IDs.
  # Local accounts are disabled, so retain a tested Entra administration path.
  azure_active_directory_role_based_access_control {
    tenant_id              = var.tenant_id
    azure_rbac_enabled     = true
    admin_group_object_ids = var.admin_group_object_ids
  }

  network_profile {
    network_plugin      = "azure"
    network_plugin_mode = "overlay"
    network_data_plane  = "cilium"
    network_policy      = "cilium"
    outbound_type       = "userAssignedNATGateway"
    service_cidr        = "172.16.0.0/16"
    dns_service_ip      = "172.16.0.10"
    pod_cidr            = "192.168.0.0/16"
  }

  oms_agent {
    log_analytics_workspace_id      = var.log_analytics_workspace_id
    msi_auth_for_monitoring_enabled = true
  }

  key_vault_secrets_provider {
    secret_rotation_enabled = true
  }

  # Let Azure own the autoscaled count while Terraform manages the rest of the pool.
  lifecycle {
    ignore_changes = [default_node_pool[0].node_count]
  }

  depends_on = [azurerm_role_assignment.kubelet_operator, azurerm_role_assignment.registry_pull]
}

# Purpose: Permit the worker-node kubelet identity to pull images from the chosen ACR.
# Creation: Grant AcrPull on var.registry_id to the explicit kubelet principal,
# and make cluster creation wait for the grant. No registry password is required.
# Important: Skipping the directory lookup helps with newly created principals;
# it does not bypass Azure authorization. This grants image pulls, not image push,
# application data access or a network path to a private registry endpoint.
resource "azurerm_role_assignment" "registry_pull" {
  scope                            = var.registry_id
  role_definition_name             = "AcrPull"
  principal_id                     = azurerm_user_assigned_identity.kubelet.principal_id
  principal_type                   = "ServicePrincipal"
  skip_service_principal_aad_check = true
}