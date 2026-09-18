# Exercise 0: remote state storage for every other exercise.
#
# This is the one configuration that cannot use the backend it creates: the
# container has to exist before anything can write state into it. So this
# exercise keeps its state on disk, and everything else keeps its state here.
module "resource_group" {
  source = "../modules/resourcegroups"

  # Deliberately not the lab's own group. ./run.sh destroy all empties that one,
  # and the state must survive it.
  name     = "${var.prefix}-tfstate-rg"
  location = var.location
  tags     = var.tags
}

module "tfstate" {
  source = "../modules/storage/tfstate"

  resource_group_name = module.resource_group.name
  location            = module.resource_group.location
  name_prefix         = var.prefix

  storage_account_name           = var.storage_account_name
  container_name                 = var.container_name
  replication_type               = var.replication_type
  retention_days                 = var.retention_days
  shared_access_key_enabled      = var.shared_access_key_enabled
  grant_current_user_blob_access = var.grant_current_user_blob_access
  allowed_ip_ranges              = var.allowed_ip_ranges
  enable_delete_lock             = var.enable_delete_lock

  tags = var.tags
}

# The account name is generated, so hardcoding it in eight backend blocks would
# mean editing eight files. This writes the shared half of the configuration to
# the repository root instead, and each root passes it to:
#   terraform init -backend-config=../backend.hcl
resource "local_file" "backend_config" {
  count = var.write_backend_config_file ? 1 : 0

  filename        = "${path.root}/../backend.hcl"
  content         = module.tfstate.backend_hcl
  file_permission = "0644"
}
