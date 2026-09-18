# IMPORTANT: this prefix must NOT match the one in the numbered exercises.
# Both configurations name resources <prefix>-something. Share a prefix and the
# two states each believe they own the same resources, and applying one starts
# undoing the other. Different prefix, different resource group, no overlap.
prefix   = "azure-terra-full"
location = "eastus2"

# exercise2: two networks. lb holds the jump host, workload the private web servers.
vnets = {
  lb       = { address_space = ["10.10.0.0/16"] }
  workload = { address_space = ["10.20.0.0/16"] }
}

# exercise3: outer key must match a VNet above, and each range must sit inside
# that VNet's address_space.
vnet_subnets = {
  lb = {
    frontend = { address_prefixes = ["10.10.1.0/24"] }
  }
  workload = {
    web = { address_prefixes = ["10.20.1.0/24"] }
  }
}

# exercise4: one NSG per subnet. Rules belong to that subnet alone.
#   source_address_prefix takes a CIDR ("203.0.113.4/32") or an Azure service tag
#   ("Internet", "VirtualNetwork", "AzureLoadBalancer"). VirtualNetwork also
#   covers peered VNets, which is how the jump host reaches the web subnet.
#   protocol defaults to "Tcp"; ICMP has no ports so use destination_port_range "*".
#   Lower priority numbers win, so keep the catch-all deny at 4096.
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
      # A Standard load balancer does not rewrite the client address, so traffic
      # it forwards still arrives from the real Internet client. Without this the
      # site breaks even though no VM has a public IP.
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

# exercise6: only the web subnet needs this. The frontend subnet's jump host has
# its own public IP, which already gives it an outbound path.
nat_gateways = {
  workload-web = {
    vnet_key    = "workload"
    subnet_name = "web"
  }
}

# exercise7: size availability is per subscription and region. The whole B-series
# is blocked on free subscriptions, so check before changing:
#   az vm list-skus -l eastus2 --resource-type virtualMachines --all \
#     --query "[?!restrictions && starts_with(name,'Standard_D2')].name" -o tsv
vms = {
  # Private backend. Reachable only through the load balancer or the jump host.
  # Needs the NAT gateway to install Apache at first boot.
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

# exercise8. The backend pool is worked out from the VMs above, so there is no
# list of VM names to keep in step here.
http_port = 80

# Azure gives a load balancer no DNS name automatically, because the frontend
# already has a static IP you own. Set a region-unique label to get one.
# lb_domain_name_label = "azure-terra-full-7391"

tags = {
  environment = "lab"
  project     = "terraform-azure"
  managed_by  = "Terraform"
}
