# Azure Terraform Training

Build an Azure network one service at a time. Each numbered directory is a
separate, independently deployable Terraform configuration with its own state,
so you apply them in order and see exactly what each service adds.

By the end you have two peered virtual networks, a private Apache web server
reachable only through a public load balancer, and a jump host you SSH into to
reach the private machine.

```
                    Internet
                       |
        +--------------+---------------+
        |                              |
  load balancer  (ex8)            jump host  (ex7)
  public IP : 80                  SSH : 22, your IP only
        |                              |
        |                  lb-vnet 10.10.0.0/16          (ex2)
        |                  └── frontend 10.10.1.0/24     (ex3)
        |                        + NSG                   (ex4)
        |                              |
        |                      VNet peering               (ex5)
        |                              |
        |                  workload-vnet 10.20.0.0/16    (ex2)
        +----------------> └── web 10.20.1.0/24          (ex3)
                                 + NSG                    (ex4)
                                 + NAT gateway            (ex6)
                                 └── web1, no public IP   (ex7)
```

## The exercises

Apply them in order. Each README explains what it builds and the traps in it.

| # | Builds | Why it comes here |
| --- | --- | --- |
| [exercise0](exercise0/) | Remote state storage | Optional, and only useful before the rest |
| [exercise1](exercise1/) | Resource group | Everything else needs somewhere to live |
| [exercise2](exercise2/) | Virtual networks | Address space, before anything can use it |
| [exercise3](exercise3/) | Subnets | Subnets are separate resources inside a VNet |
| [exercise4](exercise4/) | Network security groups | Until now nothing was filtered |
| [exercise5](exercise5/) | VNet peering | Private path between the two networks |
| [exercise6](exercise6/) | NAT gateway | Outbound Internet for VMs with no public IP |
| [exercise7](exercise7/) | Linux VMs and the SSH key | Needs the subnet, NSG and NAT to exist |
| [exercise8](exercise8/) | Load balancer | Needs the VM NICs to put in its backend pool |

Order matters. Exercise7's private VM cannot install Apache without exercise6,
and exercise8 has nothing to load balance without exercise7.

[exercise0](exercise0/) stands slightly apart. It builds no part of the network:
it creates the Azure storage account that the other exercises can keep their
state in, instead of each keeping a `terraform.tfstate` on your laptop. Skip it
and everything still works with local state. Apply it and it has to come first,
because a backend cannot be used before it exists.

Two directories sit outside the numbered chain, because neither depends on the
exercises before it:

- [remote-backend-demo](remote-backend-demo/) builds two resource groups and
  nothing else, with its state in the storage account exercise0 created. It is
  the shortest complete example of a remote backend in this repository: how to
  initialise one, how to prove the state really left your machine, what the lock
  looks like when two people run Terraform at once.
- [full-lab](full-lab/) builds the same network as exercises 1 to 8, but as a
  single configuration with one state file, so you can see what changes when the
  roots stop being separate.

## Before you start

You need an Azure subscription you may create resources in. **This lab costs
money** — VMs, a load balancer, a NAT gateway and three public IPs bill by the
hour. Destroy it when you finish a session.

| Tool | Version | Check |
| --- | --- | --- |
| Terraform | >= 1.9, < 2.0 | `terraform version` |
| Azure CLI | any recent | `az version` |

## Sign in to Azure

```bash
az login
```

A browser opens. Then choose your subscription:

```bash
az account list --output table
az account set --subscription "<your subscription name or id>"
```

Terraform reads the subscription from an environment variable, so export it in
the shell you run Terraform from:

```bash
export ARM_SUBSCRIPTION_ID=$(az account show --query id -o tsv)
```

Put that in your `~/.bashrc` to avoid repeating it. You do this once; it applies
to every exercise.

## Running the exercises

There are two ways. Use the script when you want the whole lab up; run the
commands by hand when you want to study one step.

### With the script

[`run.sh`](run.sh) walks the exercises in the right order, shows you each plan,
asks before applying it, and stops at the first failure.

```bash
./run.sh status              # which exercises are applied
./run.sh validate            # fmt check and validate, makes no Azure calls
./run.sh plan <what>         # show the plan for each exercise that can be planned
./run.sh apply <what>        # plan each, confirm, apply, in order 1 -> 8
./run.sh output <what>       # outputs of the applied exercises
./run.sh destroy <what>      # tear down in reverse order 8 -> 1
```

### Choosing which exercises

`<what>` is required on `plan`, `apply`, `output` and `destroy`, so nothing runs
by accident. `status` and `validate` always cover everything and take no target.

| Form | Means |
| --- | --- |
| `all` | every exercise, in order |
| `3` | just exercise3 |
| `1-4` | exercise1 through exercise4 |
| `exercise3` | the full directory name also works |

`all` includes exercise0, with one exception: `destroy all` leaves it alone,
because removing the state storage while the other exercises still point at it
would leave them with no state. Destroy it on its own when you mean it:
`./run.sh destroy exercise0`.

You can combine them, and repeats are ignored:

```bash
./run.sh apply all              # build the whole lab
./run.sh plan 2                 # plan exercise2 only
./run.sh apply 1-3              # the first three, in order
./run.sh apply 1-3 5            # exercise1, 2, 3 and 5
./run.sh destroy all            # reverse order, asks you to type "destroy"
./run.sh apply all --yes        # skip the confirmation prompt
```

Order is always the lab's own order, not the order you typed: `apply` runs
low to high, `destroy` runs high to low.

Some details worth knowing:

- **It applies the plan you just saw.** The plan is saved to a file and that
  exact file is applied, so nothing can change between review and apply.
- **Plans can contain secrets**, such as the generated SSH private key, so they
  are written to a private temp directory and deleted when the script exits.
- **It stops at the first failure** rather than continuing into exercises whose
  prerequisites are missing, and tells you which of the two it was: a missing
  prerequisite, or a real error in a configuration whose dependencies all exist.
- **`destroy` runs in reverse** and makes you type `destroy` in full, because
  Azure refuses to delete a resource another one still uses.
- **No answer means no apply.** If it cannot read your reply it skips the
  exercise rather than applying it.

`./run.sh plan` can only plan as far as the chain allows. Exercise2 looks the
resource group up by name, so it cannot be planned until exercise1 is applied.
Rather than printing the same lookup error eight times, the script plans what it
can and lists the rest:

```
========== Plan: exercise1 ==========
Plan: 1 to add, 0 to change, 0 to destroy.

========== Not planned yet ==========
These look up resources that do not exist until the exercises before them are applied:
  exercise2
  exercise3
  ...
```

That is normal, not a failure, and the script exits 0. As you apply each
exercise the plan reaches one step further.

### By hand

```bash
cd exercise1
terraform init      # once per exercise directory
terraform plan      # read it before applying
terraform apply     # type: yes
terraform output    # values the next exercise needs
```

Each directory keeps its own `terraform.tfstate`. Nothing is shared between
them except the names you carry forward. See [Where the state lives](#where-the-state-lives)
to move those files into Azure instead.

## Carrying values between exercises

Exercises do **not** read each other's state. Each takes the names it needs as
variables and looks the real resources up:

```hcl
data "azurerm_resource_group" "this" {
  name = var.resource_group_name
}
```

So two values must be identical in every exercise's `terraform.auto.tfvars`:

- **`prefix`** — resources are named `<prefix>-something`, and later exercises
  find earlier ones by that name. Pick your own so you do not collide with a
  colleague in the same subscription.
- **`resource_group_name`** — from `terraform output resource_group_name` in
  exercise1.

Change `prefix` in exercise1 and you must change it in all eight, and in
exercise0 if you are using it.

The tradeoff of separate state is real and you will meet it in exercise7: the
web page wants the load balancer's address, but the load balancer needs the VM
NICs first. With one big configuration Terraform resolves that itself. With
separate roots you apply exercise7, then exercise8, then re-apply exercise7.

[full-lab](full-lab/) is the other side of that tradeoff: the same network as one
configuration, where the modules reference each other directly and `prefix` is
the only value you set twice. Read it after the exercises, not instead of them.

## Where the state lives

By default each directory keeps its own `terraform.tfstate` on disk. That file is
the only record of what Terraform built, it holds the generated SSH private key
in plaintext, and it cannot be shared with anyone else.

[exercise0](exercise0/) replaces that with an Azure storage account. Apply it
once, and it writes `backend.hcl` at the repository root:

```hcl
resource_group_name  = "azure-terra-lab-tfstate-rg"
storage_account_name = "azureterralab7f3a1c"
container_name       = "tfstate"
use_azuread_auth     = false
```

Each root then declares only its own state key:

```hcl
terraform {
  backend "azurerm" {
    key = "exercise1.tfstate"
  }
}
```

and is initialised with the shared half on the command line:

```bash
terraform -chdir=exercise1 init -backend-config=../backend.hcl
```

Add `-migrate-state` if that exercise already has local state, and Terraform
uploads what you have. Locking needs nothing extra: the azurerm backend takes a
lease on the state blob itself.

`backend.hcl` holds names only, no keys, so it is safe to commit.

[remote-backend-demo](remote-backend-demo/) is that whole sequence already wired
up and working, against two throwaway resource groups. Run it before you migrate
anything you care about.

## Tear it down

```bash
./run.sh destroy all
```

Or by hand, in reverse order, because Azure will not delete a resource another
one still uses:

```bash
for d in exercise8 exercise7 exercise6 exercise5 exercise4 exercise3 exercise2 exercise1; do
  terraform -chdir=$d destroy -auto-approve
done
```

Then confirm nothing is left:

```bash
az group exists -n <prefix>-rg     # should print false
```

## Shared modules

Every exercise is a thin root that calls a module in [modules/](modules/). The
modules are the reusable part; the exercises decide what to build with them.

| Module | Creates |
| --- | --- |
| `modules/resourcegroups` | The resource group |
| `modules/networking/vnet` | One virtual network |
| `modules/networking/subnets` | Subnets inside an existing VNet |
| `modules/networking/nsg` | A security group and its subnet association |
| `modules/networking/peering` | Both directions of a VNet peering |
| `modules/networking/natgateway` | Outbound Internet for private subnets |
| `modules/vms/linux` | Every VM, plus the one SSH key they share |
| `modules/loadbalancers` | Load balancer, backend pool, probe and rule |
| `modules/storage/tfstate` | The storage account and container holding remote state |

`modules/vms/linux` is the one module called once rather than per instance, and
it loops internally. That is deliberate: the key pair in its `key.tf` must be
created once and shared by every VM, which a per-instance module cannot do.

## Troubleshooting

**`SkuNotAvailable` when creating a VM.** VM sizes are restricted per
subscription and region, and free subscriptions heavily so. The entire B-series
is typically blocked. Find one you may actually use:

```bash
az vm list-skus --location eastus2 --resource-type virtualMachines --all \
  --query "[?!restrictions && starts_with(name,'Standard_D2')].name" -o tsv
```

Put a name from that list into `size` in exercise7.

**`PublicIPCountLimitReached`.** Free subscriptions allow only 3 public IPs per
region, and this lab uses all 3: load balancer, jump host, NAT gateway.

```bash
az network list-usages --location eastus2 \
  --query "[?contains(name.value,'PublicIPAddresses')]" -o table
```

Free accounts generally cannot raise this; upgrading to pay-as-you-go is the fix.

**SSH times out.** Almost always the `allow_ssh_admin` rule in exercise4 holds
the wrong address. `curl https://api.ipify.org` is not always right, because some
ISPs show Azure a different address. Read the one Azure actually saw:

```bash
curl http://<load balancer ip> > /dev/null
az vm run-command invoke -g <prefix>-rg -n <prefix>-web1 \
  --command-id RunShellScript \
  --scripts "awk '{print \$2}' /var/log/apache2/other_vhosts_access.log | sort -u"
```

Ignore `168.63.129.16` (the Azure probe), `127.0.0.1`, and anything starting
`10.`. The remaining public address is yours.

**The page does not answer after an apply.** Cloud-init is probably still
installing Apache. Check without SSH:

```bash
az vm run-command invoke -g <prefix>-rg -n <prefix>-web1 \
  --command-id RunShellScript --scripts "cloud-init status; systemctl is-active apache2"
```

**`PublicIPAddressCannotBeDeleted`.** You turned off `public_ip_enabled` on a VM
that already had an address. Azure will not delete an address still attached to
a NIC, and Terraform does not reliably detach it first:

```bash
az network nic ip-config update -g <prefix>-rg --nic-name <prefix>-web1-nic \
  -n primary --remove publicIPAddress
az network public-ip delete -g <prefix>-rg -n <prefix>-web1-pip
terraform apply
```

**`Unsupported argument` after editing a module.** A root is passing a variable
the module no longer declares. Check the module's `variables.tf`.

**`Resource group not found` when planning.** The exercise before it has not
been applied. Exercises look each other's resources up by name, so they must be
applied in order. Check with `./run.sh status`.

## A note on security

This lab serves plain HTTP and deliberately exposes port 80 to the Internet so
the page is reachable. Do not put real data on it, do not reuse the generated
SSH key anywhere else, and destroy the lab when you are done. Port 80 is found
by Internet-wide scanners within minutes.

The generated private key is stored in `terraform.tfstate` in plaintext as well
as on disk. Treat that state file as a secret and never commit it. `.gitignore`
already excludes `*.tfstate` and `*.pem`.
