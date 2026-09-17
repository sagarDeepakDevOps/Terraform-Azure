# Loaded automatically by every plan and apply, because of the .auto.tfvars suffix.
# These are the working defaults for the lab; edit in place, no copying required.

prefix   = "azure-terra-lab"
location = "eastus2"

# Two networks, peered. Keys become resource names and are referenced by vms below.
vnets = {
  lb = {
    address_space = ["10.10.0.0/16"]
    subnets = {
      frontend = { address_prefixes = ["10.10.1.0/24"] }
    }
  }
  workload = {
    address_space = ["10.20.0.0/16"]
    subnets = {
      web = { address_prefixes = ["10.20.1.0/24"] }
      # A new key is a new subnet; keep its range inside the address_space above.
      # app = { address_prefixes = ["10.20.2.0/24"] }
    }
  }
}

vnet_peerings = {
  lb_to_workload = {
    first  = "lb"
    second = "workload"
  }
}

# Add or remove entries to change the fleet size. All VMs must share one vnet_key.
# Size availability is per subscription and region: the whole B-series is blocked on this
# subscription in eastus2, so check with `az vm list-skus -l <region> --all` before changing it.
vms = {
  web1 = {
    vnet_key   = "workload"
    subnet_key = "web"
    size       = "Standard_D2ls_v7"
  }
}

admin_username = "azureuser"
http_port      = 80

# Terraform generates one SSH key pair per VM, so there is no key to supply here.

# SSH stays closed until you name a source range. Use your own address, not "*".
# ssh_source_address_prefix = "203.0.113.4/32"

# Optional region-unique DNS name for the frontend; apply fails if it is taken.
# lb_domain_name_label = "apachelab-demo-7391"

tags = {
  environment = "lab"
  project     = "terraform-azure"
  managed_by  = "Terraform"
}
