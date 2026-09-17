variable "resource_group_name" {
  type        = string
  description = "Resource group from exercise1."
}

variable "prefix" {
  type        = string
  description = "Same prefix used in exercise1."
}

variable "backend_vm_names" {
  type        = list(string)
  description = "Short names of the web VMs from exercise7. All of them must sit in one VNet, because a Standard public load balancer takes its network from the NICs in its pool."
}

variable "http_port" {
  type        = number
  description = "Port the load balancer listens and probes on, and the port Apache serves. Must match a rule in the web subnet's NSG from exercise4."
  default     = 80
}

variable "lb_domain_name_label" {
  type        = string
  description = "Optional DNS label giving <label>.<region>.cloudapp.azure.com. Must be unique across the whole region, so an apply fails if it is taken. Null means clients use the frontend IP."
  default     = null
}

variable "tags" {
  type        = map(string)
  description = "Tags applied to the load balancer."
  default     = {}
}
