resource_group_name = "azure-terra-lab-rg"
prefix              = "azure-terra-lab"

# B-series is blocked on free subscriptions; check sizes with az vm list-skus -l eastus2 --size Standard_D -o table
vms = {
  # Private backend, reached via the load balancer or jump host; needs exercise6's NAT to install Apache.
  web1 = {
    vnet_key          = "workload"
    subnet_name       = "web"
    role              = "web"
    size              = "Standard_D2ls_v7"
    public_ip_enabled = false
  }
  # Jump host. Public IP so you can SSH in from your laptop.
  jump = {
    vnet_key          = "lb"
    subnet_name       = "frontend"
    role              = "jump"
    size              = "Standard_D2ls_v7"
    public_ip_enabled = true
  }
}

admin_username = "azureuser"

# Fill this in AFTER exercise8 and re-apply, to see the load balancer page.
# lb_public_ip = "172.176.146.99"

tags = {
  environment = "lab"
  project     = "terraform-azure"
  managed_by  = "Terraform"
}
