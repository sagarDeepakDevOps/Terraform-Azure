resource_group_name = "azure-terra-lab-rg"
prefix              = "azure-terra-lab"

# Web VMs from exercise7 only; the jump host must never receive load-balanced traffic.
backend_vm_names = ["web1"]

http_port = 80

# Azure gives a load balancer no DNS name by default; set a region-unique label to add one, then re-apply exercise7.
# lb_domain_name_label = "azure-terra-lab-7391"

tags = {
  environment = "lab"
  project     = "terraform-azure"
  managed_by  = "Terraform"
}
