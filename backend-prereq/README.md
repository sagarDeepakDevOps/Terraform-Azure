# Remote state storage for hub-spoke

The Azure storage that holds hub-spoke's Terraform state, so the state is not a
file on one laptop. Apply this once, before hub-spoke.

It is separate from the state storage the labs on the `main` branch use. The
prefix is `azure-terra-hs`, so it gets its own resource group and storage
account, and nothing here can touch theirs.

## What it builds

| Resource | Name | Why |
| --- | --- | --- |
| Resource group | `azure-terra-hs-tfstate-rg` | Not hub-spoke's `azure-terra-hs-rg`, so `terraform destroy` there never deletes the state |
| Storage account | `azureterrahs` + 6 random characters | Names are global; the random tail keeps it unique and is fixed in this root's state |
| Blob container | `tfstate` | One blob per configuration; hub-spoke writes `hub-spoke.tfstate` |
| `../backend.hcl` | local file | The shared half of the backend settings, for `terraform init -backend-config` |

The account has blob versioning on, so every earlier copy of a state file can
be restored. Deleted blobs and containers stay recoverable for
`retention_days`. The container is private, and HTTPS with TLS 1.2 is enforced.

## Run it

```bash
cd backend-prereq
terraform init
terraform apply
```

Then check the container exists:

```bash
az storage container list \
  --account-name "$(terraform output -raw storage_account_name)" -o table
```

The apply writes `../backend.hcl`:

```hcl
resource_group_name  = "azure-terra-hs-tfstate-rg"
storage_account_name = "azureterrahs1a2b3c"
container_name       = "tfstate"
use_azuread_auth     = false
```

It holds names only, no keys. `.gitignore` excludes it anyway. On a fresh
clone, regenerate it with `terraform output -raw backend_hcl > ../backend.hcl`.

## Use it from hub-spoke

```bash
cd ..
terraform init -backend-config=backend.hcl
```

If hub-spoke already has a local `terraform.tfstate`, add `-migrate-state`.
Terraform uploads it and asks you to confirm. Check the blob is there, then
delete the local file and its backup:

```bash
az storage blob list --account-name "$(terraform -chdir=backend-prereq output -raw storage_account_name)" \
  --container-name tfstate --query "[].name" -o tsv    # hub-spoke.tfstate
```

## Why this root keeps local state

A backend has to exist before Terraform can use it, so nothing can create its
own. This is the one configuration with a local `terraform.tfstate`. It is
small, and losing it costs an `az storage account list` and a
`terraform import`, not your infrastructure.

## Settings worth knowing

**Locking needs nothing extra.** The azurerm backend locks by taking a lease on
the state blob, so there is no lock table to create.

**Signing in without a key.** By default the backend fetches the account key
through ARM, which any Contributor can do. With Owner rights, set
`grant_current_user_blob_access = true` and apply. That grants you Storage Blob
Data Contributor on the container, and `backend.hcl` switches to
`use_azuread_auth = true`. Then set `shared_access_key_enabled = false` to
remove keys altogether. If `init` returns 403 straight after, the role
assignment has not propagated yet; wait a minute.

**A firewall on the account.** `allowed_ip_ranges` limits access to the
addresses listed. If yours changes, every plan fails with 403 until you update
it, which is why it is off by default.

**Deleting it.** Destroy hub-spoke first. Destroying this root while hub-spoke
still has state in it leaves hub-spoke with nothing. If you turned on
`enable_delete_lock`, set it back to false and apply before `terraform destroy`.
