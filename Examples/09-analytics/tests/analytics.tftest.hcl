mock_provider "azurerm" {}
mock_provider "azapi" {}
mock_provider "random" {}

run "lake_and_factory" {
  command = plan

  assert {
    condition     = length(output.lake_filesystems) == 3 && output.data_factory_pipeline == "demo-pipeline"
    error_message = "The lake and Data Factory demonstration pipeline must be provisioned together."
  }
}

run "analytics_platforms" {
  command = plan

  variables {
    enable_synapse                      = true
    enable_databricks                   = true
    configure_synapse_managed_endpoints = true
  }

  assert {
    condition     = output.optional_platforms.synapse && output.optional_platforms.databricks
    error_message = "Both optional analytics platforms must be selectable."
  }
}