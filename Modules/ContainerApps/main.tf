terraform {
  required_version = ">= 1.9.0, < 2.0.0"
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = ">= 4.81.0, < 5.0.0"
    }
  }
}

# Purpose: Create the shared networking and observability environment for Container Apps.
# Creation: Azure provisions a workload-profile environment on the caller's dedicated
# subnet and attaches the Log Analytics workspace by ARM ID. The Consumption profile
# is explicitly declared so the application can select it below.
# Important: Use a supported subnet size/delegation and working outbound access.
# Environment creation does not grant registry access or start this app by itself;
# the following resource creates its revision. Networking and logs can add costs.
resource "azurerm_container_app_environment" "this" {
  name                       = "${var.name}-env"
  resource_group_name        = var.resource_group_name
  location                   = var.location
  log_analytics_workspace_id = var.log_analytics_workspace_id
  infrastructure_subnet_id   = var.subnet_id
  tags                       = var.tags

  workload_profile {
    name                  = "Consumption"
    workload_profile_type = "Consumption"
  }
}

# Purpose: Run the supplied container image as a managed, HTTPS-accessible application.
# Creation: After the environment exists, Azure creates a Single-mode revision with
# 0.25 vCPU/0.5 GiB, attaches the user identity and configures that identity for ACR.
# The caller grants AcrPull first. A public image can run without first uploading an
# image to the new registry; the example's default image uses that demonstration path.
# Runtime: HTTP readiness/liveness probes check / on target_port. HTTP concurrency
# scaling controls 0-3 replicas, and all ingress traffic is assigned to the latest
# active revision. Azure manages revisions and replicas after Terraform configures them.
# Security: Ingress is external but insecure connections are disabled; application
# authentication still belongs to the workload. VNet integration is not private ingress.
# Important: The image must listen on the expected port and pass the probes. Scaling
# to zero introduces cold starts; use reviewed immutable image digests in production.
resource "azurerm_container_app" "this" {
  name                         = var.name
  resource_group_name          = var.resource_group_name
  container_app_environment_id = azurerm_container_app_environment.this.id
  revision_mode                = "Single"
  workload_profile_name        = "Consumption"
  tags                         = var.tags

  identity {
    type         = "UserAssigned"
    identity_ids = [var.identity_id]
  }

  registry {
    server   = var.registry_server
    identity = var.identity_id
  }

  template {
    min_replicas = 0
    max_replicas = 3

    container {
      name   = "app"
      image  = var.image
      cpu    = 0.25
      memory = "0.5Gi"

      readiness_probe {
        transport = "HTTP"
        port      = var.target_port
        path      = "/"
      }

      liveness_probe {
        transport = "HTTP"
        port      = var.target_port
        path      = "/"
      }
    }

    http_scale_rule {
      name                = "http"
      concurrent_requests = "20"
    }
  }

  ingress {
    external_enabled           = true
    allow_insecure_connections = false
    target_port                = var.target_port
    transport                  = "auto"

    traffic_weight {
      percentage      = 100
      latest_revision = true
    }
  }
}