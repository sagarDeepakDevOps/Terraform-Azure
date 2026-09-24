resource_group_name = "azure-terra-lab-rg"
prefix              = "azure-terra-lab"

# Only the web subnet needs NAT; the jump host goes out through its own public IP.
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
