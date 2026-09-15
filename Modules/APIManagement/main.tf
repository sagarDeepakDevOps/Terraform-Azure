terraform {
  required_version = ">= 1.9.0, < 2.0.0"
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = ">= 4.81.0, < 5.0.0"
    }
  }
}

# Purpose: Create the managed API gateway that owns API definitions, products and policies.
# Creation: AzureRM provisions Developer_1 with the caller's publisher contact and
# a system-assigned identity. Child resources reference the created service name.
# Security: Older TLS 1.0/1.1 and SSL 3.0 frontend/backend options are disabled here;
# the API below is HTTPS-only and requires a subscription.
# Important: Developer tier has recurring cost, lengthy provisioning and no production
# SLA. This service identity does not automatically have backend/data permissions.
resource "azurerm_api_management" "this" {
  name                = var.name
  resource_group_name = var.resource_group_name
  location            = var.location
  publisher_name      = var.publisher_name
  publisher_email     = var.publisher_email
  sku_name            = "Developer_1"
  tags                = var.tags

  identity {
    type = "SystemAssigned"
  }

  security {
    frontend_tls10_enabled = false
    frontend_tls11_enabled = false
    backend_tls10_enabled  = false
    backend_tls11_enabled  = false
    frontend_ssl30_enabled = false
    backend_ssl30_enabled  = false
  }
}

# Purpose: Define revision 1 of the demo API exposed beneath the gateway's /demo path.
# Creation: Add the API after APIM exists, allow only HTTPS, and require a valid
# APIM subscription key. Operations and policies below define what the API does.
# Important: An API definition is not a deployed application backend. The health
# operation uses a gateway-generated response instead of an external backend service.
resource "azurerm_api_management_api" "this" {
  name                  = "demo"
  resource_group_name   = var.resource_group_name
  api_management_name   = azurerm_api_management.this.name
  revision              = "1"
  display_name          = "Terraform Demo API"
  path                  = "demo"
  protocols             = ["https"]
  subscription_required = true
}

# Purpose: Declare GET /health as an operation within the /demo API.
# Creation: Reference the new API/service and describe its 200 response contract;
# the operation policy below provides the actual response implementation.
# Important: Declaring response status metadata does not itself execute code or
# return a healthy result from a real downstream application.
resource "azurerm_api_management_api_operation" "health" {
  operation_id        = "health"
  api_name            = azurerm_api_management_api.this.name
  api_management_name = azurerm_api_management.this.name
  resource_group_name = var.resource_group_name
  display_name        = "Health"
  method              = "GET"
  url_template        = "/health"

  response {
    status_code = 200
  }
}

# Purpose: Implement the demonstration health response and request-rate policy in APIM.
# Creation: Read health-policy.xml relative to this module and attach its policy
# document to the created operation. APIM evaluates it when an authorized request
# arrives; file() reads the local policy during Terraform configuration evaluation.
# Important: The sample returns a synthetic status, not a backend health diagnosis.
# Policy content and subscription keys must be managed separately from application code.
resource "azurerm_api_management_api_operation_policy" "this" {
  api_name            = azurerm_api_management_api.this.name
  api_management_name = azurerm_api_management.this.name
  resource_group_name = var.resource_group_name
  operation_id        = azurerm_api_management_api_operation.health.operation_id
  xml_content         = file("${path.module}/health-policy.xml")
}

# Purpose: Package the demo API for controlled subscription-based consumption.
# Creation: Add a published Demo APIs product to APIM, requiring a subscription and
# approval. Publishing the product does not create or approve a consumer subscription.
# Important: An operator must provision/approve a subscription before clients use
# its key. Product visibility and application/user authorization are separate concerns.
resource "azurerm_api_management_product" "this" {
  product_id            = "demo"
  api_management_name   = azurerm_api_management.this.name
  resource_group_name   = var.resource_group_name
  display_name          = "Demo APIs"
  subscription_required = true
  approval_required     = true
  published             = true
}

# Purpose: Include the demo API in the product consumers can subscribe to.
# Creation: Bind the existing API name and newly created product ID within the same
# APIM service; Terraform's references order this association after both resources.
# Important: This adds catalog membership only. It does not generate credentials,
# approve subscriptions, or change the operation's runtime implementation.
resource "azurerm_api_management_product_api" "this" {
  api_name            = azurerm_api_management_api.this.name
  product_id          = azurerm_api_management_product.this.product_id
  api_management_name = azurerm_api_management.this.name
  resource_group_name = var.resource_group_name
}