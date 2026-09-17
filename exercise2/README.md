# Exercise 2 — Virtual networks

Two private networks. Subnets come next, in exercise3.

## What you build

Two `azurerm_virtual_network` resources, created by one `for_each` over the
`vnets` map:

- `lb` — `10.10.0.0/16`, will hold the jump host
- `workload` — `10.20.0.0/16`, will hold the private web server

## Run it

```bash
cd exercise2
terraform init
terraform apply
```

## Check it

```bash
az network vnet list -g <your rg> -o table
```

## Worth knowing

**The address spaces must not overlap.** Exercise5 peers these two networks and
Azure rejects a peering between overlapping ranges.

**A VNet on its own does nothing.** It creates no subnet, no route to the
Internet and no VM. It is an address space reservation.

**How this exercise finds the group** — it does not read exercise1's state. It
takes the name as a variable and looks the group up:

```hcl
data "azurerm_resource_group" "this" {
  name = var.resource_group_name
}
```

That keeps every exercise independent, so you can run them days apart.
