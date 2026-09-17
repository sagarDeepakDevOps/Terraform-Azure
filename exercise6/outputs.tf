output "nat_gateway_public_ips" {
  description = "Address the routed subnets appear to come from when reaching the Internet."
  value       = { for key, nat in module.nat_gateways : key => nat.public_ip_address }
}
