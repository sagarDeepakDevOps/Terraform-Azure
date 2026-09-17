# Loaded automatically by every plan and apply, because of the .auto.tfvars suffix.
# Every input the configuration accepts is listed here, so this file is the only
# place you need to edit. Nothing here is secret: Terraform generates the SSH key.

# ---------------------------------------------------------------------------
# Naming and region
# ---------------------------------------------------------------------------
# prefix is joined to every resource name, e.g. <prefix>-web1, <prefix>-lb.
prefix = "azure-terra-lab"

# All resources go in this one region. SKU availability differs per region.
location = "eastus2"

# ---------------------------------------------------------------------------
# Networks, subnets, and each subnet's own firewall
# ---------------------------------------------------------------------------
# Each vnets key is one VNet. Each subnet key is one Azure subnet AND one NSG
# named <prefix>-<vnet>-<subnet>-nsg, carrying only that subnet's nsg_rules.
# Rules are no longer shared: opening a port here affects this subnet alone.
#
# Writing a rule:
#   priority               lower numbers win; keep the catch-all deny at 4096
#   destination_port_range "80", "8080", "1000-2000", or "*"
#   source_address_prefix  a CIDR ("203.0.113.4/32") or an Azure service tag
#                          ("Internet", "VirtualNetwork", "AzureLoadBalancer").
#                          VirtualNetwork includes peered VNets.
#   protocol               defaults to "Tcp"; also "Udp", "Icmp" or "*".
#                          ICMP has no ports, so use destination_port_range "*"
#   direction              defaults to "Inbound"; access defaults to "Allow"
#
# nat_gateway_enabled gives a subnet outbound Internet without public IPs on its
# VMs. Required for any subnet whose VMs are private, or cloud-init cannot reach
# the apt mirrors and Apache never installs. It is a billable resource and it
# consumes one public IP of its own.
#
# QUOTA: this subscription allows only 3 public IPs in this region, and the lab
# uses all 3 (load balancer, jump host, NAT gateway). Giving any further VM a
# public IP fails until you free one.
#
# Turning public_ip_enabled off for a VM that already has an address is a
# two-step change, because Azure refuses to delete an address still attached to
# a NIC and Terraform does not reliably detach it first:
#   az network nic ip-config update -g <rg> --nic-name <vm>-nic -n primary \
#     --remove publicIpAddress
#   az network public-ip delete -g <rg> -n <vm>-pip
#   terraform apply
vnets = {
  # Front door network: holds the jump host you SSH into.
  lb = {
    address_space = ["10.10.0.0/16"]
    subnets = {
      frontend = {
        address_prefixes    = ["10.10.1.0/24"]
        nat_gateway_enabled = false
        nsg_rules = {
          # Your public IP as AZURE sees it, so only you can SSH in.
          # Do not trust "what is my IP" sites: this ISP shows Azure a different
          # address than it shows them. Re-derive it with the command in the
          # README note below if SSH starts timing out after an ISP rotation.
          allow_ssh_admin = {
            priority               = 100
            destination_port_range = "22"
            source_address_prefix  = "157.49.31.49/32" # add your ip here
          }
          # Everything else is dropped. Keep last.
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
  }

  # Backend network: private Apache VMs, reachable only through the load
  # balancer or from the jump host across the peering.
  workload = {
    address_space = ["10.20.0.0/16"]
    subnets = {
      web = {
        address_prefixes    = ["10.20.1.0/24"]
        nat_gateway_enabled = true
        nsg_rules = {
          # A Standard load balancer does not rewrite the client address, so
          # traffic it forwards still arrives from the real Internet client.
          # Removing this rule breaks the site even though no VM is public.
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
          # Lets the jump host ping and SSH these VMs across the peering.
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
          # Everything else is dropped. Keep last.
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
  }
}

# Connects two VNets privately in both directions. first and second are vnets keys.
vnet_peerings = {
  lb_to_workload = {
    first  = "lb"
    second = "workload"
  }
}

# ---------------------------------------------------------------------------
# Virtual machines
# ---------------------------------------------------------------------------
# All VMs share one generated SSH key.
#   role "web"  = installs Apache and joins the load balancer pool.
#   role "jump" = plain host, no Apache, not load balanced.
#   All "web" VMs must share one vnet_key, because a Standard public load
#   balancer takes its network from the NICs in its backend pool.
#   size availability is per subscription and region; the whole B-series is
#   blocked here, so check `az vm list-skus -l <region> --all` before changing.
#   public_ip_enabled false keeps a VM off the Internet entirely. Such a VM
#   needs nat_gateway_enabled on its subnet to install packages at first boot.
vms = {
  # Private backend. No public IP: reachable only via the load balancer or the
  # jump host. Its subnet's NAT gateway provides the outbound path.
  web1 = {
    vnet_key          = "workload"
    subnet_key        = "web"
    role              = "web"
    size              = "Standard_D2ls_v7"
    public_ip_enabled = false
  }
  # Jump host. Public IP so you can SSH in from your laptop.
  jump = {
    vnet_key          = "lb"
    subnet_key        = "frontend"
    role              = "jump"
    size              = "Standard_D2ls_v7"
    public_ip_enabled = true
  }
}

# Login user on every VM. Password login is disabled; only the generated key works.
admin_username = "azureuser"

# ---------------------------------------------------------------------------
# Load balancer
# ---------------------------------------------------------------------------
# Port Apache serves on, and the port the load balancer listens and probes on.
# Change this and you must change the matching ports in the web subnet's rules.
http_port = 80

# null means clients use the frontend IP. Set a region-unique label to get
# <label>.<region>.cloudapp.azure.com; apply fails if the label is taken.
# Setting this replaces the web VMs, because it changes their cloud-init.
lb_domain_name_label = null

# ---------------------------------------------------------------------------
# Tags applied to every taggable resource
# ---------------------------------------------------------------------------
tags = {
  environment = "lab"
  project     = "terraform-azure"
  managed_by  = "Terraform"
}
