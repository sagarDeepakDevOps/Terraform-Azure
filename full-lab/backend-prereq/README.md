# Exercise 0 — Remote state storage

Every other exercise writes `terraform.tfstate` next to its own `main.tf`. That
file is the only record of what Terraform built, it holds the generated SSH
private key in plaintext, and it lives on one laptop. This exercise builds the
Azure storage that replaces it.

It comes before exercise1 because the container has to exist before anything can
write state into it.

## What you build

A resource group of its own, a storage account, and one blob container.

The resource group is **not** the lab's group. `./run.sh destroy all` empties
`<prefix>-rg`, and the state has to survive that, so it lives in
`<prefix>-tfstate-rg` instead.

## Run it

```bash
cd full-lab/backend-prereq
terraform init
terraform apply
```

## Check it

```bash
terraform output storage_account_name

az storage container list \
  --account-name $(terraform output -raw storage_account_name) \
  -o table
```

That command fetches the account key over ARM, which is what the defaults here
allow. If you set `shared_access_key_enabled = false` there is no key to fetch,
so add `--auth-mode login` and the CLI signs in as you instead.

## Carry forward

The apply writes [`../backend.hcl`](../backend.hcl) into `full-lab/`:

```hcl
resource_group_name  = "azure-terra-lab-tfstate-rg"
storage_account_name = "azureterralab7f3a1c"
container_name       = "tfstate"
use_azuread_auth     = false
```

It holds names only, no keys, so it is safe to commit. `full-lab` then needs
just its own state key:

```hcl
terraform {
  backend "azurerm" {
    key = "full-lab.tfstate"
  }
}
```

and is initialised with the shared half on the command line:

```bash
terraform -chdir=full-lab init -backend-config=backend.hcl
```

If you would rather spell it out in full, `terraform output backend_block_example`
prints a complete block to paste.

## Moving state that already exists

If you have already applied full-lab with local state, do not delete the local
file. Uncomment the backend block, then let Terraform copy it up:

```bash
cd full-lab
terraform init -backend-config=backend.hcl -migrate-state
```

It reads the local state, uploads it, and asks you to confirm. Check the
container afterwards, then delete `terraform.tfstate` and its backup.

## Why this one keeps local state

A backend has to exist before Terraform can use it, so nothing can create its
own. That is the whole reason this is a separate configuration: it is the only
one with a local `terraform.tfstate`, and it is small enough that losing it
costs you an `az storage account list` and a `terraform import`.

You *can* migrate this exercise into its own container once it exists, and it
works. It just means that destroying the lab's state storage now requires the
state that is inside it, so the recovery path when something goes wrong is much
worse. Leave it local.

## Worth knowing

**Locking needs nothing extra.** The azurerm backend locks by taking a lease on
the state blob itself. There is no second resource to create, unlike S3, which
needs a DynamoDB table.

**Versioning is the undo button.** `versioning_enabled` keeps the previous
contents of the blob every time an apply overwrites it, so a bad apply or a
`terraform state rm` is recoverable. Soft delete (`retention_days`) covers the
blob being deleted outright.

**State is still a secret.** Remote state is encrypted at rest and access is
controlled, but anyone who can read the container can read every value in it,
including the lab's SSH private key. That is why the container is private and
`allow_nested_items_to_be_public` is false.

**Two ways to authenticate, and they have different prerequisites.** By default
the backend asks ARM for an account key, which any subscription Contributor can
do. Setting `grant_current_user_blob_access = true` creates a role assignment so
the backend can sign in as you instead (`use_azuread_auth = true`), and then
`shared_access_key_enabled = false` removes account keys altogether. Creating
that role assignment needs Owner or User Access Administrator.

**Role assignments take a minute to take effect.** If `terraform init` returns
403 right after this apply, wait a minute and run it again.

**The storage account name is generated once.** It is `<prefix without
hyphens><6 random characters>` and is held in this exercise's state, so it does
not change on later applies. If the name collides with somebody else's account
anywhere in Azure, force a new one:

```bash
terraform apply -replace=module.tfstate.random_string.suffix
```

That renames the account, which means re-initialising every other root.

**`./run.sh destroy all` will not touch this exercise.** Destroying the state
storage while other configurations still point at it leaves them with no state
at all. Name it explicitly when you really mean it:

```bash
./run.sh destroy exercise0
```
