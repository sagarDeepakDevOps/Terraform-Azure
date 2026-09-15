mock_provider "azurerm" {}
mock_provider "random" {}

run "front_door_waf" {
  command = plan

  assert {
    condition     = output.waf_mode == "Prevention"
    error_message = "The managed Front Door WAF must block matching attacks."
  }
}

run "all_delivery_options" {
  command = plan

  variables {
    enable_application_gateway   = true
    gateway_backend_hostnames    = ["backend.example.com"]
    gateway_listener_hostname    = "gateway.example.com"
    gateway_certificate_base64   = "bW9jay1vbmx5"
    gateway_certificate_password = "MockOnly-NotARealCredential"
    traffic_manager_endpoints = {
      primary   = { hostname = "primary.example.com", priority = 1 }
      secondary = { hostname = "secondary.example.com", priority = 2 }
    }
  }

  assert {
    condition     = length(module.application_gateway) == 1 && length(module.traffic_manager) == 1
    error_message = "Both optional delivery services must be selectable with their required inputs."
  }
}