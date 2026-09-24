resource_group_name = "azure-terra-lab-rg"
prefix              = "azure-terra-lab"

# Outer key must match an exercise2 VNet, and each range must sit inside its address_space.
vnet_subnets = {
  lb = {
    frontend = { address_prefixes = ["10.10.1.0/24"] }
  }
  workload = {
    web = { address_prefixes = ["10.20.1.0/24"] }
  }
}
