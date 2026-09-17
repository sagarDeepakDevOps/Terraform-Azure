resource_group_name = "azure-terra-lab-rg"
prefix              = "azure-terra-lab"

# Only the web subnet needs this. The frontend subnet's jump host has its own
# public IP, which already gives it an outbound path.
nat_gateways = {
  workload-web = {
    vnet_key    = "workload"
    subnet_name = "web"
  }
}

tags = {
  environment = "lab"
  project     = "terraform-azure"
  managed_by  = "Terraform"
}
