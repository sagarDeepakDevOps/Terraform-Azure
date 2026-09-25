# Must differ from full-lab and the exercises, or two states will claim the same resources.
prefix   = "azure-terra-hs"
location = "eastus2"

admin_username = "azureuser"

# Azure fixes these subnet names, and each must be at least /26.
hub = {
  address_space = ["10.0.0.0/22"]
  subnets = {
    AzureFirewallSubnet           = { address_prefixes = ["10.0.0.0/26"] }
    AzureFirewallManagementSubnet = { address_prefixes = ["10.0.0.64/26"] }
    AzureBastionSubnet            = { address_prefixes = ["10.0.1.0/26"] }
  }
  firewall_sku_tier = "Basic"
  bastion_sku       = "Standard"
}

# Ranges must not overlap the hub or each other.
spokes = {
  web = {
    address_space = ["10.1.0.0/16"]
    subnets = {
      frontend = {
        address_prefixes = ["10.1.1.0/24"]
        nsg_rules = {
          # Internet clients arrive through the firewall's DNAT, which SNATs them to an AzureFirewallSubnet address.
          allow_http_from_firewall = {
            priority                = 100
            destination_port_ranges = ["80"]
            source_address_prefixes = ["10.0.0.0/26"]
          }
          allow_ssh_from_bastion = {
            priority                = 110
            destination_port_ranges = ["22"]
            source_address_prefixes = ["10.0.1.0/26"]
          }
          allow_icmp_from_api = {
            priority                = 120
            protocol                = "Icmp"
            source_address_prefixes = ["10.2.0.0/16"]
          }
          # Replaces Azure's default AllowVnetInBound, which would otherwise let every peered network in.
          deny_all_inbound = {
            priority                = 4096
            access                  = "Deny"
            protocol                = "*"
            source_address_prefixes = ["*"]
          }
        }
      }
    }
  }

  api = {
    address_space = ["10.2.0.0/16"]
    subnets = {
      backend = {
        address_prefixes = ["10.2.1.0/24"]
        nsg_rules = {
          # Spoke-to-spoke traffic is not SNATed, so the source is the calling VM's own address.
          allow_http_from_web = {
            priority                = 100
            destination_port_ranges = ["80"]
            source_address_prefixes = ["10.1.0.0/16"]
          }
          allow_ssh_from_bastion = {
            priority                = 110
            destination_port_ranges = ["22"]
            source_address_prefixes = ["10.0.1.0/26"]
          }
          allow_icmp_from_web = {
            priority                = 120
            protocol                = "Icmp"
            source_address_prefixes = ["10.1.0.0/16"]
          }
          deny_all_inbound = {
            priority                = 4096
            access                  = "Deny"
            protocol                = "*"
            source_address_prefixes = ["*"]
          }
        }
      }
    }
  }
}

vms = {
  web1 = {
    spoke_key          = "web"
    subnet_key         = "frontend"
    private_ip_address = "10.1.1.10"
  }
  api1 = {
    spoke_key          = "api"
    subnet_key         = "backend"
    private_ip_address = "10.2.1.10"
  }
}

# Inbound. Publishes web1:80 on the firewall's public IP.
firewall_dnat_rules = {
  web1-http = {
    vm_key = "web1"
    port   = 80
  }
}

# Spoke to spoke. Rules are stateful, so replies need no rule; web may call api, api may not call web.
firewall_network_rules = {
  web-to-api-http = {
    source_spokes      = ["web"]
    destination_spokes = ["api"]
    protocols          = ["TCP"]
    destination_ports  = ["80"]
  }
  spokes-icmp = {
    source_spokes      = ["web", "api"]
    destination_spokes = ["web", "api"]
    protocols          = ["ICMP"]
    destination_ports  = ["*"]
  }
}

# Outbound. Spokes reach only these FQDNs on the Internet; cloud-init needs them to install Apache.
firewall_application_rules = {
  ubuntu-packages = {
    source_spokes     = ["web", "api"]
    destination_fqdns = ["*.ubuntu.com", "azure.archive.ubuntu.com"]
  }
}

tags = {
  environment = "lab"
  project     = "terraform-azure-hub-spoke"
  managed_by  = "Terraform"
}
