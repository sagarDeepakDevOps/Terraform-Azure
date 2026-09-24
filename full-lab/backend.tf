# Remote state, commented out until backend-prereq has been applied.
#
# Apply backend-prereq first. It creates the storage account and writes
# backend.hcl into this folder, which holds the storage account settings.
# Then uncomment this block and run:
#
#   terraform init -backend-config=backend.hcl
#
# If you already have local state, add -migrate-state to that command and
# Terraform uploads it for you.
#
# terraform {
#   backend "azurerm" {
#     key = "full-lab.tfstate"
#   }
# }
