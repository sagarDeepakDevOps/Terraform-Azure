# Remote backend demo: resource groups, and nothing else.
#
# The file worth reading here is backend.tf. What this configuration builds is
# deliberately the smallest useful thing in Azure, so that what you are watching
# is where the state goes, not what the resources do.
module "resource_groups" {
  source   = "../modules/resourcegroups"
  for_each = var.resource_groups

  # A group may override the region; most will not, and inherit var.location.
  name     = "${var.prefix}-${each.key}-rg"
  location = coalesce(each.value.location, var.location)
  tags     = merge(var.tags, each.value.tags)
}
