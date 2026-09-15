resource "random_id" "suffix" {
  byte_length = 3
}

locals {
  name = "${var.prefix}${random_id.suffix.hex}"
}

module "resource_group" {
  source   = "../../Modules/ResourceGroups"
  name     = "${var.prefix}-rg"
  location = var.location
  tags     = var.tags
}

module "web" {
  source              = "../../Modules/AppService"
  name                = "${local.name}-origin"
  resource_group_name = module.resource_group.name
  location            = var.location
  front_door_only     = true
  front_door_id       = module.front_door.resource_guid
  tags                = var.tags
}

module "front_door" {
  source              = "../../Modules/FrontDoor"
  name                = "${local.name}-fd"
  resource_group_name = module.resource_group.name
  origin_hostname     = module.web.hostname
  tags                = var.tags
}

module "dns" {
  source              = "../../Modules/DNS"
  name                = var.dns_zone_name
  resource_group_name = module.resource_group.name
  cname_records       = { edge = module.front_door.hostname }
  tags                = var.tags
}

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

module "traffic_manager" {
  source              = "../../Modules/TrafficManager"
  count               = length(var.traffic_manager_endpoints) > 0 ? 1 : 0
  name                = "${local.name}-tm"
  resource_group_name = module.resource_group.name
  endpoints           = var.traffic_manager_endpoints
  tags                = var.tags
}