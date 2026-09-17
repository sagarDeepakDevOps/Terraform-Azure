resource_group_name = "azure-terra-lab-rg"
prefix              = "azure-terra-lab"

# Peering is not transitive and does not bypass either subnet's NSG rules.
vnet_peerings = {
  lb_to_workload = {
    first  = "lb"
    second = "workload"
  }
}
