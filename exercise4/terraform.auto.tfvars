resource_group_name = "azure-terra-lab-rg"
prefix              = "azure-terra-lab"

# One NSG per subnet. Rules belong to that subnet alone.
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

tags = {
  environment = "lab"
  project     = "terraform-azure"
  managed_by  = "Terraform"
}
