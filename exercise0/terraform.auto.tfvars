# Use the SAME prefix as the other exercises. It names the state resource group
# and seeds the generated storage account name.
prefix   = "azure-terra-lab"
location = "eastus2"

# One blob per configuration lives in here: exercise1.tfstate, exercise2.tfstate,
# and so on. One container is enough; the blob key is what separates them.
container_name = "tfstate"

# Leave null to get <prefix without hyphens><6 random characters>, which is what
# makes the name globally unique. Set it only if you must match a naming standard.
# storage_account_name = "azureterralabtfstate01"

# LRS is the cheapest and is fine for a lab. Real state belongs in ZRS or GRS.
replication_type = "LRS"
retention_days   = 7

# Authentication. The defaults work for anyone with Contributor on the
# subscription: the backend fetches an account key over ARM.
#
# The stricter setup, if you have Owner or User Access Administrator, is to flip
# both of these. The backend then signs in as you and no account key exists:
#   shared_access_key_enabled      = false
#   grant_current_user_blob_access = true
shared_access_key_enabled      = true
grant_current_user_blob_access = false

# Empty means the account is reachable from anywhere, which is what you want
# while learning. Lock it to your own address with a BARE IP, not a /32:
#   allowed_ip_ranges = ["157.49.31.49"]
allowed_ip_ranges = []

# Turn this on once the lab is real. Remember it blocks terraform destroy here
# until you set it back to false and apply.
enable_delete_lock = false

tags = {
  environment = "lab"
  project     = "terraform-azure"
  managed_by  = "Terraform"
  purpose     = "terraform-state"
}
