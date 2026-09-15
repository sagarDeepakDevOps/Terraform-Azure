# Purpose: Generate a suffix for the globally unique backend storage account name.
# Creation: The Random provider generates three bytes locally and exposes them as
# six hexadecimal characters. This is a Terraform-managed value, not an Azure
# resource, and it stays the same while this resource remains in the same state.
# Important: A fresh state generates a new suffix. Keep bootstrap state securely;
# losing it loses Terraform's mapping to the existing backend infrastructure.
resource "random_id" "suffix" {
  byte_length = 3
}

# Purpose: Give the shared Terraform backend its own resource group and lifecycle.
# Creation: Load the local ResourceGroups module, pass the requested prefix,
# location and tags, and create the group through the root AzureRM provider.
# Its name output is used below, so Terraform creates the group before storage.
# Important: This group is separate from each demo's workload resource group.
module "resource_group" {
  source   = "../../Modules/ResourceGroups"
  name     = "${var.prefix}-rg"
  location = var.location
  tags     = var.tags
}

# Purpose: Create the durable Blob Storage backend that later holds workload state.
# Creation: The Storage module builds a StorageV2 account and a private tfstate
# container after the resource group exists. The random suffix reduces naming
# collisions; ZRS replicates data across availability zones within one region.
# Security: Shared keys and anonymous blob access are disabled. The public network
# endpoint stays enabled only so explicitly allowed runner IPs can reach it; Entra
# data permissions are still required. Versioning and soft deletion aid recovery.
# Important: This bootstrap initially uses local state. Terraform cannot initialize
# a remote backend that does not yet exist; configure each workload backend later.
module "storage" {
  source                        = "../../Modules/Storage"
  name                          = "${var.prefix}${random_id.suffix.hex}"
  resource_group_name           = module.resource_group.name
  location                      = var.location
  replication_type              = "ZRS"
  public_network_access_enabled = true
  allowed_ip_addresses          = var.runner_public_ip_addresses
  containers                    = ["tfstate"]
  tags                          = var.tags
}

# Purpose: Authorize the selected operators and CI identities to read, write and
# lease state blobs without sharing a storage account access key.
# Creation: Convert state_principals into named role assignments. Each grant uses
# the existing principal's object ID/type and the new tfstate container's ARM ID;
# those references order container creation before role assignment creation.
# Security: Storage Blob Data Contributor is scoped to this container, not the
# subscription. The caller must already have permission to create role grants.
# Important: An RBAC grant does not bypass the storage firewall, and Azure role
# propagation can delay initial backend access even after Terraform reports success.
module "state_roles" {
  source = "../../Modules/RoleAssignments"
  assignments = {
    for name, principal in var.state_principals : name => {
      scope          = module.storage.container_ids["tfstate"]
      role           = "Storage Blob Data Contributor"
      principal_id   = principal.object_id
      principal_type = principal.principal_type
    }
  }
}

# Purpose: Guard the shared backend account against accidental Azure deletion.
# Creation: Apply the Locks module's CanNotDelete lock to the account only after
# the storage objects and writer grants are created, as expressed by depends_on.
# Important: This management lock is different from Terraform's Blob lease used
# for concurrent state locking. An authorized Terraform destroy can remove this
# lock, so retain the backend until all dependent states are migrated or retired.
module "lock" {
  source = "../../Modules/Governance/Locks"
  scope  = module.storage.id

  depends_on = [module.storage, module.state_roles]
}