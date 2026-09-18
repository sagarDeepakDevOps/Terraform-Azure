# Remote state, commented out until exercise0 has been applied.
#
# Apply exercise0 first. It creates the storage account and writes backend.hcl at
# the repository root, which holds the three values shared by every root here.
# Then uncomment this block and run:
#
#   terraform init -backend-config=../backend.hcl
#
# If you already have local state, add -migrate-state to that command and
# Terraform uploads it for you.
#
# terraform {
#   backend "azurerm" {
#     key = "full-lab.tfstate"
#   }
# }
