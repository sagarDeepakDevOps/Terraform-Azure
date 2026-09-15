mock_provider "azurerm" {}
mock_provider "azapi" {}
mock_provider "random" {}

run "state_security" {
  command = plan

  variables {
    runner_public_ip_addresses = ["203.0.113.10"]
    state_principals = {
      operator = { object_id = "00000000-0000-0000-0000-000000000001", principal_type = "User" }
    }
  }

  assert {
    condition     = !output.storage_security.shared_access_key_enabled && output.backend_authentication.use_azuread_auth
    error_message = "Terraform state must use Entra authorization instead of shared account keys."
  }

  assert {
    condition     = output.container_name == "tfstate"
    error_message = "The backend container name must match the documented configuration."
  }
}