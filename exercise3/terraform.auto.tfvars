resource_group_name = "azure-terra-lab-rg"
prefix              = "azure-terra-lab"

# Outer key must match a VNet short name from exercise2.
# Each range must sit inside that VNet's address_space.
vnet_subnets = {
  lb = {
    frontend = { address_prefixes = ["10.10.1.0/24"] }
  }
  workload = {
    web = { address_prefixes = ["10.20.1.0/24"] }
  }
}
