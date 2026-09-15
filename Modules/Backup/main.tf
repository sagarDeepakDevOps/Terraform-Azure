terraform {
  required_version = ">= 1.9.0, < 2.0.0"
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = ">= 4.81.0, < 5.0.0"
    }
  }
}

# Purpose: Create the Azure Backup vault that owns VM protection policies and points.
# Creation: AzureRM provisions a Standard Recovery Services vault in the requested
# region with locally redundant backup storage. Policy/binding resources below use
# its name, which establishes their dependency on successful vault creation.
# Important: Place protected VMs in a compatible region. Azure's secure-by-default
# soft deletion applies; retained/deleted backup items can delay vault cleanup.
# Local redundancy is not cross-region disaster recovery or a tested restore plan.
resource "azurerm_recovery_services_vault" "this" {
  name                = var.name
  resource_group_name = var.resource_group_name
  location            = var.location
  sku                 = "Standard"
  storage_mode_type   = "LocallyRedundant"
  tags                = var.tags
}

# Purpose: Define when VM backups run and how many daily recovery points are retained.
# Creation: Add a daily policy to the newly created vault, scheduled at 03:00 UTC
# and retaining var.retention_days daily points. The policy alone protects no VM;
# the bindings below enroll the selected machines into this schedule.
# Important: Choose a retention period for the workload's recovery/compliance needs.
# Terraform creates policy metadata; Azure Backup performs later backup jobs.
resource "azurerm_backup_policy_vm" "this" {
  name                = "daily-vm-backup"
  resource_group_name = var.resource_group_name
  recovery_vault_name = azurerm_recovery_services_vault.this.name
  timezone            = "UTC"

  backup {
    frequency = "Daily"
    time      = "03:00"
  }

  retention_daily {
    count = var.retention_days
  }
}

# Purpose: Enroll each selected VM in the vault's daily backup policy.
# Creation: for_each uses stable map keys to bind each existing VM ID to the vault
# and policy created above. These references order enrollment after those resources
# are available; Azure Backup then manages scheduled recovery-point creation.
# Important: Check backup job success and perform a restore test. Removing a binding
# is not permission to discard required data; retention and soft-delete behavior
# must be reviewed before destroying protected VMs, the policy or the vault.
resource "azurerm_backup_protected_vm" "this" {
  for_each            = var.virtual_machine_ids
  resource_group_name = var.resource_group_name
  recovery_vault_name = azurerm_recovery_services_vault.this.name
  source_vm_id        = each.value
  backup_policy_id    = azurerm_backup_policy_vm.this.id
}