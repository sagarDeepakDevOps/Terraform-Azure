# Purpose: Generate a state-retained local suffix for globally named edge/origin services.
# Creation: Random returns three bytes as hex; Azure resources consume the naming
# local below. A new state generates a new suffix, not a recovery of old resources.
resource "random_id" "suffix" {
  byte_length = 3
}

# Purpose: Derive one consistent base name without creating another Azure object.
# Evaluation: Append the Random provider's suffix to the caller's prefix.
locals {
  name = "${var.prefix}${random_id.suffix.hex}"
}

# Purpose: Group the edge-delivery lab's resources under a separate lifecycle.
# Creation: Create the group before modules that consume its name output.
module "resource_group" {
  source   = "../../Modules/ResourceGroups"
  name     = "${var.prefix}-rg"
  location = var.location
  tags     = var.tags
}

# Purpose: Host an origin that only this Front Door instance may reach through its app path.
# Creation: Pass the Front Door profile resource_guid into the Web App's service-tag/
# header restriction. Terraform tracks underlying resource dependencies: the profile
# can exist before the web origin, and the origin registration follows the web hostname.
# Important: Do not add a mutual whole-module depends_on cycle. Application code
# and health still need deployment; a restricted hosting resource is not a healthy app.
module "web" {
  source              = "../../Modules/AppService"
  name                = "${local.name}-origin"
  resource_group_name = module.resource_group.name
  location            = var.location
  front_door_only     = true
  front_door_id       = module.front_door.resource_guid
  tags                = var.tags
}

# Purpose: Create the global Premium HTTPS entry point and managed WAF for the origin.
# Creation: The module builds profile/endpoint first, then registers module.web.hostname
# in its origin group and route. Its profile GUID feeds the origin restriction above.
# Important: This default lab has recurring Premium cost and creates no custom-domain binding.
module "front_door" {
  source              = "../../Modules/FrontDoor"
  name                = "${local.name}-fd"
  resource_group_name = module.resource_group.name
  origin_hostname     = module.web.hostname
  tags                = var.tags
}

# Purpose: Show how an Azure public DNS zone can alias an edge name to Front Door.
# Creation: Create the selected zone and an edge CNAME using the actual endpoint hostname.
# Important: The default example domain is not a registered customer domain. Registrar
# delegation, ownership verification and TLS binding are separate; use the default FD URL first.
module "dns" {
  source              = "../../Modules/DNS"
  name                = var.dns_zone_name
  resource_group_name = module.resource_group.name
  cname_records       = { edge = module.front_door.hostname }
  tags                = var.tags
}

# Purpose: Reserve a dedicated subnet only when the independent Application Gateway is selected.
# Creation: count follows enable_application_gateway; create its own VNet and /24
# gateway subnet, whose ID is used by the optional gateway module below.
# Important: This is not an automatically added hop between Front Door and its Web App.
module "gateway_network" {
  source              = "../../Modules/Vnet"
  count               = var.enable_application_gateway ? 1 : 0
  name                = "${var.prefix}-gateway-vnet"
  resource_group_name = module.resource_group.name
  location            = var.location
  address_space       = ["10.80.0.0/16"]
  subnets = {
    gateway = { address_prefixes = ["10.80.1.0/24"] }
  }
  tags = var.tags
}

# Purpose: Demonstrate a separate regional HTTPS WAF gateway with caller-owned TLS material.
# Creation: When enabled, use the dedicated subnet plus supplied backend hostnames,
# listener hostname and base64 PFX/password to build the gateway and its health/routing policy.
# Important: Supply real trusted certificates and healthy reachable backends; the
# Front-Door-only origin is not automatically eligible for this independent gateway.
# The PFX private key/password are sensitive in state and WAF_v2 has recurring costs.
module "application_gateway" {
  source               = "../../Modules/ApplicationGateway"
  count                = var.enable_application_gateway ? 1 : 0
  name                 = "${var.prefix}-appgw"
  resource_group_name  = module.resource_group.name
  location             = var.location
  subnet_id            = module.gateway_network[0].subnet_ids["gateway"]
  backend_hostnames    = var.gateway_backend_hostnames
  listener_hostname    = var.gateway_listener_hostname
  certificate_base64   = var.gateway_certificate_base64
  certificate_password = var.gateway_certificate_password
  tags                 = var.tags
}

# Purpose: Optionally compare DNS priority failover with HTTP reverse-proxy delivery.
# Creation: A nonempty endpoint map enables the module; its input validation requires
# at least two external endpoints with unique priorities. Terraform registers them,
# but does not create their applications, DNS/TLS bindings or regional data replication.
module "traffic_manager" {
  source              = "../../Modules/TrafficManager"
  count               = length(var.traffic_manager_endpoints) > 0 ? 1 : 0
  name                = "${local.name}-tm"
  resource_group_name = module.resource_group.name
  endpoints           = var.traffic_manager_endpoints
  tags                = var.tags
}