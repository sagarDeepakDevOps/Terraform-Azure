mock_provider "azurerm" {}
mock_provider "azapi" {}
mock_provider "random" {}

run "hosting_contract" {
  command = plan

  assert {
    condition     = output.web_https_only
    error_message = "Web hosting must enforce HTTPS."
  }

  assert {
    condition     = output.function_storage_authentication == "UserAssignedIdentity"
    error_message = "Functions must use managed identity for deployment storage."
  }
}