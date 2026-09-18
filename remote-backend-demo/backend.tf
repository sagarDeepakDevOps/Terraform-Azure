# This is the whole point of this directory.
#
# There are two ways to configure a backend and both are written out below.
# Option A is active. To use option B, comment out A and uncomment B.

# ---------------------------------------------------------------------------
# Option A: partial configuration, shared with every other root  (ACTIVE)
# ---------------------------------------------------------------------------
# Only the state key lives here, because it is the only value unique to this
# configuration. The other three come from backend.hcl at the repository root,
# which exercise0 generated, and are supplied at init time:
#
#   terraform init -backend-config=../backend.hcl
#
# This is what you want once several roots share one storage account: the
# account name is written down in one file instead of copied into all of them.
terraform {
  backend "azurerm" {
    key = "remote-backend-demo.tfstate"
  }
}

# ---------------------------------------------------------------------------
# Option B: everything inline, so plain "terraform init" is enough
# ---------------------------------------------------------------------------
# Nothing outside this directory is needed, which is what you want for a
# self-contained demo, or for a single root that owns its own backend.
#
# Replace the two names below with yours. exercise0 prints them:
#
#   terraform -chdir=../exercise0 output state_resource_group_name
#   terraform -chdir=../exercise0 output storage_account_name
#
# Then this is the entire command:
#
#   terraform init
#
# The storage account name is generated and globally unique, so the one below is
# an example and will not exist in your subscription.
#
# terraform {
#   backend "azurerm" {
#     resource_group_name  = "azure-terra-lab-tfstate-rg"
#     storage_account_name = "azureterralab7f3a1c"
#     container_name       = "tfstate"
#     key                  = "remote-backend-demo.tfstate"
#
#     # Only if you set grant_current_user_blob_access = true in exercise0.
#     # Leave it out and the backend fetches an account key over ARM instead.
#     # use_azuread_auth = true
#   }
# }
#
# The cost of writing it out here is that the account name is now in two places
# if another root also uses this backend, and a generated name is exactly the
# kind of value you do not want to copy by hand. That is the tradeoff option A
# exists to solve.
