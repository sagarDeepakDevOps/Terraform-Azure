# Names the state resource group and seeds the generated storage account name.
prefix   = "azure-terra-lab"
location = "eastus2"

# One container holds every configuration's state; each uses its own blob key.
container_name = "tfstate"

# Leave null for a generated, globally unique name; set it only to match a naming standard.
# storage_account_name = "azureterralabtfstate01"

# LRS is the cheapest and is fine for a lab. Real state belongs in ZRS or GRS.
replication_type = "LRS"
retention_days   = 7

# Defaults use an account key; with Owner rights, flip both so the backend signs in as you with no key.
shared_access_key_enabled      = true
grant_current_user_blob_access = false

# Empty allows any address; to restrict it, list bare IPs without /32, e.g. ["157.49.31.49"].
allowed_ip_ranges = []

# Blocks terraform destroy here until set back to false and applied; enable once the lab is real.
enable_delete_lock = false

tags = {
  environment = "lab"
  project     = "terraform-azure"
  managed_by  = "Terraform"
  purpose     = "terraform-state"
}
