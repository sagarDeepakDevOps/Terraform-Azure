mock_provider "azurerm" {
  mock_data "azurerm_client_config" {
    defaults = { tenant_id = "00000000-0000-0000-0000-000000000001" }
  }
}

mock_provider "azapi" {}
mock_provider "random" {}

run "private_ai_defaults" {
  command = plan

  assert {
    condition     = !output.search_local_authentication && length(output.openai_deployments) == 0
    error_message = "Search must use Entra auth and OpenAI models must be opt-in."
  }
}

run "ai_and_ml_options" {
  command = plan

  variables {
    enable_openai           = true
    enable_machine_learning = true
    openai_deployments = {
      demo = { model_name = "gpt-4o", model_version = "2024-11-20" }
    }
  }

  assert {
    condition     = output.ml_storage_access == "Identity" && contains(output.openai_deployments, "demo")
    error_message = "ML must use identity-based storage and explicitly requested model deployments must be wired."
  }
}