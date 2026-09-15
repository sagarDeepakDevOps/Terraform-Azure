# Purpose: Define the CLI/provider compatibility for this independently deployable root.
# Initialization: terraform init resolves a single compatible AzureRM version across
# these module calls, and .terraform.lock.hcl records its exact version/checksums.
# Important: Child modules declare compatibility; this root selects the tested minor
# release. Keep its lock file in Git and review upgrades before changing the constraint.
terraform {
  required_version = ">= 1.9.0, < 2.0.0"

  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 4.81.0"
    }
  }
}