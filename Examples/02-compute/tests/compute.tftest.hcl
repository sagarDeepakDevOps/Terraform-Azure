mock_provider "azurerm" {}

variables {
  ssh_public_key = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIAEBAQEBAQEBAQEBAQEBAQEBAQEBAQEBAQEBAQEBAQEB test-only"
}

run "default_compute" {
  command = plan

  assert {
    condition     = length(output.linux_private_ips) == 2
    error_message = "The load balancer example needs two Linux backends."
  }

  assert {
    condition     = !output.optional_components.windows && !output.optional_components.scale_set && !output.optional_components.backup
    error_message = "Additional paid compute components must be opt-in."
  }
}

run "all_compute_options" {
  command = plan

  variables {
    enable_windows         = true
    windows_admin_password = "MockOnly-NotARealCredential-123!"
    enable_scale_set       = true
    enable_backup          = true
  }

  assert {
    condition     = output.optional_components.windows && output.optional_components.scale_set && output.optional_components.backup
    error_message = "All optional compute modules must be plannable together."
  }
}