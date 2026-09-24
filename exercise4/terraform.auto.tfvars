resource_group_name = "azure-terra-lab-rg"
prefix              = "azure-terra-lab"

# One NSG per subnet; sources take a CIDR or service tag, and the lowest priority number wins.
nsgs = {
  lb-frontend = {
    vnet_key    = "lb"
    subnet_name = "frontend"
    rules = {
      # REPLACE with your own public IP as Azure sees it. See the exercise README.
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

tags = {
  environment = "lab"
  project     = "terraform-azure"
  managed_by  = "Terraform"
}
