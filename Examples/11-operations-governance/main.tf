resource "random_id" "suffix" {
  byte_length = 3
}

module "resource_group" {
  source   = "../../Modules/ResourceGroups"
  name     = "${var.prefix}-rg"
  location = var.location
  tags     = var.tags
}

module "web" {
  source              = "../../Modules/AppService"
  name                = "${var.prefix}${random_id.suffix.hex}-app"
  resource_group_name = module.resource_group.name
  location            = var.location
  tags                = var.tags
}

module "logs" {
  source              = "../../Modules/Monitoring/LogAnalytics"
  name                = "${var.prefix}-logs"
  resource_group_name = module.resource_group.name
  location            = var.location
  tags                = var.tags
}

module "diagnostics" {
  source             = "../../Modules/Monitoring/DiagnosticSettings"
  target_resource_id = module.web.id
  workspace_id       = module.logs.id
}

module "alerts" {
  source              = "../../Modules/Monitoring/Alerts"
  name                = "${var.prefix}-http-errors"
  resource_group_name = module.resource_group.name
  target_resource_id  = module.web.id
  notification_email  = var.notification_email
  tags                = var.tags
}

module "policy" {
  source            = "../../Modules/Governance/Policy"
  resource_group_id = module.resource_group.id
  allowed_locations = [var.location]
  enforce           = var.enforce_policy
}

module "budget" {
  source            = "../../Modules/Governance/Budget"
  count             = var.enable_budget ? 1 : 0
  name              = "${var.prefix}-monthly"
  resource_group_id = module.resource_group.id
  start_date        = var.budget_start_date
  contact_emails    = [var.notification_email]
}

module "automation" {
  source              = "../../Modules/Automation"
  name                = "${var.prefix}-automation"
  resource_group_name = module.resource_group.name
  location            = var.location
  tags                = var.tags
}

module "sentinel" {
  source       = "../../Modules/Security/Sentinel"
  count        = var.enable_sentinel ? 1 : 0
  workspace_id = module.logs.id
}

module "defender" {
  source = "../../Modules/Security/Defender"
  count  = var.enable_subscription_defender ? 1 : 0
}

module "lock" {
  source = "../../Modules/Governance/Locks"
  count  = var.enable_lock ? 1 : 0
  scope  = module.resource_group.id

  depends_on = [module.web, module.logs, module.diagnostics, module.alerts, module.policy, module.budget, module.automation, module.sentinel]
}