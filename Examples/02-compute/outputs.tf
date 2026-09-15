output "demo_url" {
  description = "HTTP-only teaching endpoint. Do not send credentials or production traffic."
  value       = "http://${module.load_balancer.public_ip_address}"
}

output "linux_private_ips" {
  description = "Private backend VM addresses. No public SSH or RDP is opened."
  value       = { for name, vm in module.linux : name => vm.private_ip_address }
}

output "optional_components" {
  description = "Which optional paid services were selected."
  value = {
    windows   = var.enable_windows
    scale_set = var.enable_scale_set
    backup    = var.enable_backup
  }
}