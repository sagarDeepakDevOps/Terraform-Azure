# Same prefix as hub-spoke; it must differ from full-lab's, so the two never share a state account.
prefix   = "azure-terra-hs"
location = "eastus2"

container_name = "tfstate"

# Leave null for a generated, globally unique name.
# storage_account_name = "azureterrahstfstate01"

# LRS is the cheapest and is fine for a lab. Real state belongs in ZRS or GRS.
replication_type = "LRS"
retention_days   = 7

# Defaults use an account key; with Owner rights, flip both so the backend signs in as you with no key.
shared_access_key_enabled      = true
grant_current_user_blob_access = false

# Empty allows any address; to restrict it, list bare IPs without /32.
allowed_ip_ranges = []

# Blocks terraform destroy here until set back to false and applied.
enable_delete_lock = false

tags = {
  environment = "lab"
  project     = "terraform-azure-hub-spoke"
  managed_by  = "Terraform"
  purpose     = "terraform-state"
}
