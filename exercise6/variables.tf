variable "resource_group_name" {
  type        = string
  description = "Resource group from exercise1."
}

variable "prefix" {
  type        = string
  description = "Same prefix used in exercise1."
}

variable "nat_gateways" {
  type = map(object({
    vnet_key    = string
    subnet_name = string
  }))
  description = "Subnets that need outbound Internet without public IPs on their VMs. Each gateway consumes one public IP and is billable."
}

variable "tags" {
  type        = map(string)
  description = "Tags applied to every NAT gateway."
  default     = {}
}
