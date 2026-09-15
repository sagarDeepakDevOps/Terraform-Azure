mock_provider "azurerm" {
  mock_data "azurerm_client_config" {
    defaults = { tenant_id = "00000000-0000-0000-0000-000000000001" }
  }
}

mock_provider "random" {}

run "container_apps_defaults" {
  command = plan

  assert {
    condition     = !output.registry_admin_enabled
    error_message = "ACR must not enable shared administrator credentials."
  }

  assert {
    condition     = output.aks_private == null
    error_message = "AKS must be opt-in."
  }
}

run "private_aks" {
  command = plan

  variables {
    enable_aks                 = true
    aks_admin_group_object_ids = ["00000000-0000-0000-0000-000000000002"]
  }

  assert {
    condition     = output.aks_private
    error_message = "The AKS Kubernetes API must be private."
  }
}