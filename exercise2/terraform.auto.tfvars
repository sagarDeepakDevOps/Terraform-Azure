# From exercise1: terraform output resource_group_name
resource_group_name = "azure-terra-lab-rg"
prefix              = "azure-terra-lab"

# Two networks. lb holds the jump host, workload holds the private web servers.
vnets = {
  lb       = { address_space = ["10.10.0.0/16"] }
  workload = { address_space = ["10.20.0.0/16"] }
}

tags = {
  environment = "lab"
  project     = "terraform-azure"
  managed_by  = "Terraform"
}
