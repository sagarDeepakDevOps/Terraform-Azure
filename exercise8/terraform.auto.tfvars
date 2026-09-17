resource_group_name = "azure-terra-lab-rg"
prefix              = "azure-terra-lab"

# Short names of the role "web" VMs from exercise7. Do not list the jump host:
# it is not a web server and must not receive load-balanced traffic.
backend_vm_names = ["web1"]

http_port = 80

# Azure does not give a load balancer a DNS name automatically, unlike AWS,
# because the frontend already has a static IP you own. Set a region-unique
# label here to get one. This also means re-applying exercise7.
# lb_domain_name_label = "azure-terra-lab-7391"

tags = {
  environment = "lab"
  project     = "terraform-azure"
  managed_by  = "Terraform"
}
