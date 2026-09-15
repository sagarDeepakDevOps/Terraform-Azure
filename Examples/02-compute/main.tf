# Purpose: Isolate this compute lab's resources from other examples and shared state.
# Creation: The ResourceGroups module creates the named group; its name output
# supplies the prerequisite used by each compute/network module below.
module "resource_group" {
  source   = "../../Modules/ResourceGroups"
  name     = "${var.prefix}-rg"
  location = var.location
  tags     = var.tags
}

# Purpose: Create the private workload subnet used by standalone VMs and the optional VMSS.
# Creation: Build 10.30.0.0/16 with workload at 10.30.1.0/24 in the new group.
# The VNet child module returns a stable workload subnet ID for NICs, NSG and NAT.
# Important: Default outbound access is disabled; the NAT module supplies explicit egress.
module "network" {
  source              = "../../Modules/Vnet"
  name                = "${var.prefix}-vnet"
  resource_group_name = module.resource_group.name
  location            = var.location
  address_space       = ["10.30.0.0/16"]
  subnets = {
    workload = { address_prefixes = ["10.30.1.0/24"] }
  }
  tags = var.tags
}

# Purpose: Permit only the sample web traffic and load-balancer health probes inbound.
# Creation: The NSG module expands the HTTP/probe allow rules and final deny, then
# associates them with the workload subnet returned by the network module.
# Important: No SSH/RDP rule is added. A public HTTP teaching endpoint is not a
# production TLS or administration-access design.
module "nsg" {
  source              = "../../Modules/Vnet/NSG"
  name                = "${var.prefix}-nsg"
  resource_group_name = module.resource_group.name
  location            = var.location
  subnet_ids          = { workload = module.network.subnet_ids["workload"] }
  rules = {
    allow_http = {
      priority = 100, destination_port_range = "80", source_address_prefix = "Internet"
    }
    allow_probe = {
      priority = 110, destination_port_range = "80", source_address_prefix = "AzureLoadBalancer"
    }
    deny_other_inbound = {
      priority = 4096, access = "Deny", protocol = "*", destination_port_range = "*", source_address_prefix = "*"
    }
  }
  tags = var.tags
}

# Purpose: Give private VMs a predictable outbound path for package installation.
# Creation: Create the NAT gateway, its Standard public IP and the workload-subnet
# association after network creation. VM modules explicitly wait for this whole module.
# Important: Egress is billable and does not expose guest SSH/RDP from the Internet.
module "nat" {
  source              = "../../Modules/Vnet/NATGateway"
  name                = "${var.prefix}-nat"
  resource_group_name = module.resource_group.name
  location            = var.location
  subnet_ids          = { workload = module.network.subnet_ids["workload"] }
  tags                = var.tags
}

# Purpose: Create two independent private Linux web backends from one reusable module.
# Creation: for_each uses stable web01/web02 keys; each instance gets its own VM/NIC,
# the workload subnet and the supplied public SSH key. filebase64 encodes the local
# cloud-init YAML that installs Nginx inside the guest on startup.
# Important: depends_on waits for NAT/NSG readiness before VM provisioning, but guest
# package installation must still complete before the load balancer can mark it healthy.
module "linux" {
  source   = "../../Modules/VMS/Linux"
  for_each = toset(["web01", "web02"])

  name                = "${var.prefix}-${each.key}"
  resource_group_name = module.resource_group.name
  location            = var.location
  subnet_id           = module.network.subnet_ids["workload"]
  ssh_public_key      = var.ssh_public_key
  custom_data         = filebase64("${path.module}/cloud-init.yaml")
  tags                = var.tags

  depends_on = [module.nat, module.nsg]
}

# Purpose: Present one public HTTP endpoint for the two private Linux backends.
# Creation: Convert module.linux outputs into a stable name-to-NIC map and pass it
# to the LoadBalancers module, which creates pool membership, a health probe and rule.
# Important: The module uses explicit NAT rather than LB-rule outbound SNAT.
# Serving both VMs depends on their actual web process/health, not just NIC creation.
module "load_balancer" {
  source              = "../../Modules/LoadBalancers"
  name                = "${var.prefix}-lb"
  resource_group_name = module.resource_group.name
  location            = var.location
  backend_nic_ids     = { for name, vm in module.linux : name => vm.network_interface_id }
  tags                = var.tags
}

# Purpose: Add a private Windows Server example only when explicitly requested.
# Creation: count is 1 when enable_windows is true and 0 otherwise; reuse the group,
# subnet and supplied sensitive administrator password after NAT/NSG prerequisites.
# Important: This adds VM/disk cost but no RDP access path or domain join. Turning
# the flag off after deployment plans removal; it does not pause an existing VM.
module "windows" {
  source              = "../../Modules/VMS/Windows"
  count               = var.enable_windows ? 1 : 0
  name                = "${var.prefix}-windows"
  resource_group_name = module.resource_group.name
  location            = var.location
  subnet_id           = module.network.subnet_ids["workload"]
  admin_password      = var.windows_admin_password
  tags                = var.tags

  depends_on = [module.nat, module.nsg]
}

# Purpose: Demonstrate optional CPU-based autoscaling behind the same load balancer.
# Creation: When enabled, pass the existing pool ID, workload subnet, SSH key and
# cloud-init to VMScaleSets. Terraform orders the module after its dependencies;
# Azure Monitor later adjusts instance count within the module's bounds.
# Important: This adds backends alongside the two standalone VMs, not in place of
# them. Costs and guest startup time increase when additional instances are created.
module "scale_set" {
  source              = "../../Modules/VMScaleSets"
  count               = var.enable_scale_set ? 1 : 0
  name                = "${var.prefix}-vmss"
  resource_group_name = module.resource_group.name
  location            = var.location
  subnet_id           = module.network.subnet_ids["workload"]
  backend_pool_id     = module.load_balancer.backend_pool_id
  ssh_public_key      = var.ssh_public_key
  custom_data         = filebase64("${path.module}/cloud-init.yaml")
  tags                = var.tags

  depends_on = [module.nat, module.nsg]
}

# Purpose: Optionally protect the two standalone Linux VMs with Azure Backup.
# Creation: Build a name-to-VM-ID map and pass it to the vault/policy/protection
# module, so enrollment follows VM creation. Windows and VMSS are not in this map.
# Important: Verify backup jobs and retained data before cleanup; disabling the flag
# is not a harmless pause and may require protection/retention decisions.
module "backup" {
  source              = "../../Modules/Backup"
  count               = var.enable_backup ? 1 : 0
  name                = "${var.prefix}-vault"
  resource_group_name = module.resource_group.name
  location            = var.location
  virtual_machine_ids = { for name, vm in module.linux : name => vm.id }
  tags                = var.tags
}