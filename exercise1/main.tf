# Exercise 1: the resource group every later exercise deploys into.
module "resource_group" {
  source = "../modules/resourcegroups"

  name     = "${var.prefix}-rg"
  location = var.location
  tags     = var.tags
}
