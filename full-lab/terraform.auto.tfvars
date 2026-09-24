# Must differ from the numbered exercises' prefix, or both states will claim the same resources.
prefix   = "azure-terra-full"
location = "eastus2"

# exercise2: two networks. lb holds the jump host, workload the private web servers.
vnets = {
  lb       = { address_space = ["10.10.0.0/16"] }
  workload = { address_space = ["10.20.0.0/16"] }
}

# exercise3: outer key must match a VNet above, and each range must sit inside its address_space.
vnet_subnets = {
  lb = {
    frontend = { address_prefixes = ["10.10.1.0/24"] }
  }
  workload = {
    web = { address_prefixes = ["10.20.1.0/24"] }
  }
}

# exercise4: one NSG per subnet; sources take a CIDR or service tag, and the lowest priority number wins.
nsgs = {
  lb-frontend = {
    vnet_key    = "lb"
    subnet_name = "frontend"
    rules = {
      # REPLACE with your own public IP as Azure sees it, or SSH will time out.
      allow_ssh_admin = {
        priority               = 100
        destination_port_range = "22"
        source_address_prefix  = "157.49.31.49/32"
      }
      deny_other_inbound = {
        priority               = 4096
        access                 = "Deny"
        protocol               = "*"
        destination_port_range = "*"
        source_address_prefix  = "*"
      }
    }
  }

  workload-web = {
    vnet_key    = "workload"
    subnet_name = "web"
    rules = {
      # A Standard load balancer keeps the client's source IP, so HTTP must be allowed from Internet.
      allow_http_from_lb_clients = {
        priority               = 100
        destination_port_range = "80"
        source_address_prefix  = "Internet"
      }
      allow_lb_health_probe = {
        priority               = 110
        destination_port_range = "80"
        source_address_prefix  = "AzureLoadBalancer"
      }
      # Let the jump host ping, SSH and curl these VMs across the peering.
      allow_icmp_from_vnets = {
        priority               = 120
        protocol               = "Icmp"
        destination_port_range = "*"
        source_address_prefix  = "VirtualNetwork"
      }
      allow_ssh_from_vnets = {
        priority               = 130
        destination_port_range = "22"
        source_address_prefix  = "VirtualNetwork"
      }
      allow_http_from_vnets = {
        priority               = 140
        destination_port_range = "80"
        source_address_prefix  = "VirtualNetwork"
      }
      deny_other_inbound = {
        priority               = 4096
        access                 = "Deny"
        protocol               = "*"
        destination_port_range = "*"
        source_address_prefix  = "*"
      }
    }
  }
}

# exercise5: peering is not transitive and does not bypass either subnet's NSG.
vnet_peerings = {
  lb_to_workload = {
    first  = "lb"
    second = "workload"
  }
}

# exercise6: only the web subnet needs NAT; the jump host goes out through its own public IP.
nat_gateways = {
  workload-web = {
    vnet_key    = "workload"
    subnet_name = "web"
  }
}

# exercise7: B-series is blocked on free subscriptions; check sizes with az vm list-skus -l eastus2 --size Standard_D -o table
vms = {
  # Private backend, reached via the load balancer or jump host; needs the NAT gateway to install Apache.
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

# exercise8. The backend pool comes from the web-role VMs above, so there is no name list to maintain.
http_port = 80

# Azure gives a load balancer no DNS name by default; set a region-unique label to add one.
# lb_domain_name_label = "azure-terra-full-7391"

tags = {
  environment = "lab"
  project     = "terraform-azure"
  managed_by  = "Terraform"
}
