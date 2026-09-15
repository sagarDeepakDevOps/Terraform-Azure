mock_provider "azurerm" {}
mock_provider "azapi" {}
mock_provider "random" {}

run "integration_defaults" {
  command = plan

  assert {
    condition     = !output.local_authentication.service_bus && !output.local_authentication.event_hubs
    error_message = "Messaging must use Entra identities instead of shared keys."
  }

  assert {
    condition     = !output.workflow_enabled
    error_message = "Scheduled workflow execution must be opt-in."
  }
}

run "api_and_workflow" {
  command = plan

  variables {
    enable_api_management = true
    publisher_email       = "platform@example.com"
    enable_workflow       = true
  }

  assert {
    condition     = length(module.api_management) == 1 && output.workflow_enabled
    error_message = "The API and workflow options must be wired into the example."
  }
}