mock_provider "azurerm" {
  mock_data "azurerm_client_config" {
    defaults = {
      tenant_id = "00000000-0000-0000-0000-000000000001"
    }
  }
}

run "all_database_engines" {
  command = plan

  variables {
    databases = { sql = true, postgresql = true, mysql = true, cosmos = true, redis = true }
  }

  assert {
    condition     = alltrue(values(output.selected_databases))
    error_message = "All five database engines must be selectable together."
  }

  assert {
    condition     = length(output.private_endpoint_services) == 8
    error_message = "Cosmos DB and Managed Redis must each receive a private endpoint and DNS zone."
  }
}

mock_provider "azapi" {}
mock_provider "random" {}

run "private_data_defaults" {
  command = plan

  assert {
    condition     = !output.storage_security.public_network_access_enabled && !output.storage_security.shared_access_key_enabled
    error_message = "Storage must remain private and disallow shared keys."
  }

  assert {
    condition     = output.storage_security.min_tls_version == "TLS1_2"
    error_message = "Storage must require TLS 1.2."
  }

  assert {
    condition     = contains(output.private_endpoint_services, "sql") && length(output.private_endpoint_services) == 6
    error_message = "The default data lab needs storage, vault and SQL private connectivity."
  }
}