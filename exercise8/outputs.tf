output "load_balancer_public_ip" {
  description = "Frontend IPv4 address. Put this into exercise7 as lb_public_ip and re-apply to finish the demo page."
  value       = module.load_balancer.public_ip_address
}

output "load_balancer_url" {
  description = "Open this in a browser. It is the only way in, because the web VMs have no public IP."
  value       = "http://${coalesce(module.load_balancer.public_ip_fqdn, module.load_balancer.public_ip_address)}"
}
