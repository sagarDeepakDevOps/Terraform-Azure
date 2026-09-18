# A prefix of its own, so this demo cannot collide with the numbered exercises
# (azure-terra-lab) or with full-lab (azure-terra-full).
prefix   = "azure-terra-demo"
location = "eastus2"

# Resource groups are free and instant, which is exactly what you want when the
# subject is the state file rather than the infrastructure.
resource_groups = {
  app  = {}
  data = {}

  # Groups can override the region. Uncomment to watch one resource change while
  # the rest of the state stays put.
  # archive = { location = "westus2", tags = { tier = "cold" } }
}

tags = {
  environment = "demo"
  project     = "terraform-azure"
  managed_by  = "Terraform"
}
