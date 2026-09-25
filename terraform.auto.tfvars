# Must differ from full-lab and the exercises, or two states will claim the same resources.
prefix   = "azure-terra-hs"
location = "eastus2"

admin_username = "azureuser"

# Azure fixes the first three subnet names, and each must be at least /26.
hub = {
  address_space = ["10.0.0.0/22"]
  subnets = {
    AzureFirewallSubnet           = { address_prefixes = ["10.0.0.0/26"] }
    AzureFirewallManagementSubnet = { address_prefixes = ["10.0.0.64/26"] }
    AzureBastionSubnet            = { address_prefixes = ["10.0.1.0/26"] }

    # Hub VMs. Internet traffic goes through the firewall; spoke traffic goes straight over the peering.
    shared = {
      address_prefixes   = ["10.0.2.0/24"]
      route_via_firewall = true
      nsg_rules = {
        allow_ssh_from_bastion = {
          priority                = 100
          destination_port_ranges = ["22"]
          source_address_prefixes = ["10.0.1.0/26"]
        }
        allow_icmp_from_spokes = {
          priority                = 120
          protocol                = "Icmp"
          source_address_prefixes = ["10.1.0.0/16", "10.2.0.0/16"]
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
          # Hub VMs reach spokes directly over the peering, so the source is their own address.
          allow_http_from_hub = {
            priority                = 130
            destination_port_ranges = ["80"]
            source_address_prefixes = ["10.0.2.0/24"]
          }
          allow_icmp_from_hub = {
            priority                = 140
            protocol                = "Icmp"
            source_address_prefixes = ["10.0.2.0/24"]
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
          allow_ssh_from_bastion = {
            priority                = 110
            destination_port_ranges = ["22"]
            source_address_prefixes = ["10.0.1.0/26"]
          }
          # Spoke-to-spoke traffic is not SNATed, so the source is the calling VM's own address.
          allow_icmp_from_web = {
            priority                = 120
            protocol                = "Icmp"
            source_address_prefixes = ["10.1.0.0/16"]
          }
          allow_icmp_from_hub = {
            priority                = 140
            protocol                = "Icmp"
            source_address_prefixes = ["10.0.2.0/24"]
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

# vnet_key is hub or a spoke key. Only web1 runs Apache; hub1 and api1 are plain hosts for connectivity tests.
vms = {
  hub1 = {
    vnet_key           = "hub"
    subnet_key         = "shared"
    private_ip_address = "10.0.2.10"
  }
  web1 = {
    vnet_key           = "web"
    subnet_key         = "frontend"
    private_ip_address = "10.1.1.10"
    install_apache     = true
  }
  api1 = {
    vnet_key           = "api"
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

# Spoke to spoke: ping only. Anything else between spokes, such as api1 to web1 on port 80, is denied.
firewall_network_rules = {
  spokes-icmp = {
    source_spokes      = ["web", "api"]
    destination_spokes = ["web", "api"]
    protocols          = ["ICMP"]
    destination_ports  = ["*"]
  }
}

# Outbound. VMs reach only these FQDNs on the Internet; cloud-init needs them to install Apache.
firewall_application_rules = {
  ubuntu-packages = {
    source_vnets      = ["hub", "web", "api"]
    destination_fqdns = ["*.ubuntu.com", "azure.archive.ubuntu.com"]
  }
}

tags = {
  environment = "lab"
  project     = "terraform-azure-hub-spoke"
  managed_by  = "Terraform"
}
