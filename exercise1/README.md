# Exercise 1 — Resource group

Every Azure resource lives in a resource group. This one owns the whole lab, so
deleting it at the end removes everything in one step.

## What you build

A single `azurerm_resource_group`.

## Run it

```bash
cd exercise1
terraform init
terraform plan
terraform apply
```

## Check it

```bash
terraform output
az group show -n $(terraform output -raw resource_group_name) -o table
```

## Carry forward

```bash
terraform output resource_group_name
```

Put that value into `resource_group_name` in every later exercise's
`terraform.auto.tfvars`. Keep `prefix` identical everywhere too, because later
exercises find resources by name.

## Worth knowing

A resource group's `location` records only where its **metadata** lives. A group
in `eastus2` can hold a VM in `westeurope`. Later exercises read the region from
this group with a data source, so you set it only once, here.
