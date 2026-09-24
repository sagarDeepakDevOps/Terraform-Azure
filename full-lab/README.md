# full-lab — the whole lab in one configuration

Exercises 1 to 8 build this network as eight separate roots. This directory
builds the same network as one: one `terraform apply`, one state file, one
dependency graph.

It is not a ninth exercise. It is the same lab, assembled the way you would
actually write it once you have understood the pieces, so work through the
numbered exercises first and come here to see what changes.

## Run it

```bash
cd full-lab
terraform init
terraform plan
terraform apply
```

Then open the load balancer:

```bash
curl $(terraform output -raw load_balancer_url)
```

Allow about a minute after apply returns. Cloud-init is still installing Apache.

## It uses a different prefix, on purpose

`terraform.auto.tfvars` sets `prefix = "azure-terra-full"`, not the exercises'
`azure-terra-lab`. Both configurations name everything `<prefix>-something`, so
sharing a prefix would give you two state files that each believe they own the
same resources, and applying one would start undoing the other.

Different prefix means a different resource group, so the two can sit side by
side in one subscription. **This lab costs money** — running both doubles it.

## What is different from the exercises

**Modules reference each other directly.** The exercises pass names in variables
and look the real resources up:

```hcl
data "azurerm_resource_group" "this" {
  name = var.resource_group_name
}
```

Here there is nothing to look up, because the resource group is in the same
graph:

```hcl
resource_group_name = module.resource_group.name
```

That is the actual benefit. Not fewer files — fewer things that must be kept
identical by hand. `resource_group_name` is gone from the tfvars entirely, and a
typo in it is no longer possible.

**The exercise7 and exercise8 two-step is gone.** In the exercises the web VM
wants the load balancer's address for its demo page, and the load balancer wants
the VM's NIC for its backend pool. Two separate roots resolve that by applying
exercise7, then exercise8, then exercise7 again.

One root cannot do that, because module to module it is a cycle and Terraform
refuses to build one. The fix is in [`main.tf`](main.tf): the frontend public IP
is created **in the root**, not inside the load balancer module. The address
depends on neither module, and both depend on it, so the cycle disappears. The
load balancer module takes it through its `existing_public_ip` variable.

That is the general shape of the fix whenever two modules seem to need each
other: find the one resource they are really fighting over and hoist it up a
level.

**Ordering that used to be free now has to be stated.** Applying eight roots in
sequence guaranteed the NSG and NAT gateway existed before any VM booted.
Terraform only orders what it can see, and nothing in the VM module reads either
of them, so the VM module carries a `depends_on`:

```hcl
depends_on = [module.nsgs, module.nat_gateways]
```

Without it Terraform may build a NIC in a subnet while the NAT gateway is still
attaching to it — Azure rejects concurrent writes to one subnet — and the web VM
can boot with no route to the Ubuntu archive, so cloud-init never installs
Apache.

**The backend pool is derived, not listed.** Exercise8 takes
`backend_vm_names = ["web1"]`. Here the load balancer pools every VM whose
`role` is `web`, so there is no second list to keep in step and the jump host
cannot accidentally end up behind the load balancer.

**Variables validate each other.** Terraform 1.9 allows a variable's validation
to reference another variable, so a `vnet_key` that names no VNet, or a
`subnet_name` that names no subnet, is caught at plan time with a sentence that
says so, rather than as a missing map key deep inside a module.

## What you give up

**Blast radius.** One state file means one `terraform destroy` can remove
everything, and one bad apply can touch anything. The exercises cannot damage
what is not in their own state.

**Iteration speed.** Every plan refreshes every resource in the lab, not the
eight you are currently working on.

**Reading order.** The exercises exist to be read one service at a time. This
file is the whole network at once, which is harder to meet for the first time.

Splitting state is a real technique, not just a teaching device. The judgement
is where to draw the line: usually around things with different lifecycles and
different owners, not around each service.

## Remote state

[`backend.tf`](backend.tf) holds a commented-out `azurerm` backend. Apply
[backend-prereq](backend-prereq/) first, which creates the storage and writes
`backend.hcl` into this folder, then uncomment the block and run:

```bash
terraform init -backend-config=backend.hcl
```

If this configuration already has local state, add `-migrate-state` and
Terraform uploads what you have.

## Tear it down

```bash
terraform destroy
```

`run.sh` does not know about this directory — it only drives `exercise*` — so
there is no ordering to arrange. One state file, one destroy, reverse order
worked out for you.
