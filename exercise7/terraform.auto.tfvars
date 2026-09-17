resource_group_name = "azure-terra-lab-rg"
prefix              = "azure-terra-lab"

# size availability is per subscription and region. The whole B-series is blocked
# on free subscriptions, so check before changing:
#   az vm list-skus -l eastus2 --resource-type virtualMachines --all \
#     --query "[?!restrictions && starts_with(name,'Standard_D2')].name" -o tsv
vms = {
  # Private backend. Reachable only through the load balancer or the jump host.
  # Needs the NAT gateway from exercise6 to install Apache at first boot.
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
