# Shared settings come from backend.hcl, which backend-prereq writes: terraform init -backend-config=backend.hcl
terraform {
  backend "azurerm" {
    key = "hub-spoke.tfstate"
  }
}
