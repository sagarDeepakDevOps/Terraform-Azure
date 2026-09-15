terraform {
  required_version = ">= 1.9.0, < 2.0.0"
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = ">= 4.81.0, < 5.0.0"
    }
  }
}

# Purpose: Create the private Azure ML workspace that organizes future ML assets and jobs.
# Creation: AzureRM connects the supplied Application Insights, Key Vault and storage
# resource IDs, then attaches a pre-authorized user-assigned workspace identity.
# storage_account_access_type=Identity selects identity-based access rather than
# an account key; the caller grants its required storage/vault/monitoring roles first.
# Networking: Public workspace access is disabled. A managed network with Internet
# outbound capability is described, but provision_on_creation_enabled=false leaves
# its provisioning/connection approvals to the explicit later setup stage.
# Important: Private inbound DNS/endpoints do not complete the managed outbound path.
# No notebook VM, training cluster, image-build compute or inference endpoint is
# created here. Configure those assets, private dependencies and user authorization
# before training; assess job, storage, telemetry and network costs separately.
resource "azurerm_machine_learning_workspace" "this" {
  name                           = var.name
  resource_group_name            = var.resource_group_name
  location                       = var.location
  application_insights_id        = var.application_insights_id
  key_vault_id                   = var.key_vault_id
  storage_account_id             = var.storage_account_id
  storage_account_access_type    = "Identity"
  primary_user_assigned_identity = var.identity_id
  public_network_access_enabled  = false
  friendly_name                  = "Terraform ML demo"
  tags                           = var.tags

  identity {
    type         = "UserAssigned"
    identity_ids = [var.identity_id]
  }

  managed_network {
    isolation_mode                = "AllowInternetOutbound"
    provision_on_creation_enabled = false
  }
}