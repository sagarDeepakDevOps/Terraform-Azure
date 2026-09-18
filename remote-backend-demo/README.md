# remote-backend-demo — a remote backend, end to end

Every other directory in this repository keeps its state on disk. This one keeps
it in the storage account [exercise0](../exercise0/) built, and it builds two
resource groups so there is something in that state to look at.

The infrastructure is beside the point. [`backend.tf`](backend.tf) is the
exercise.

## Before you start

Apply [exercise0](../exercise0/) first. It creates the storage account and writes
`backend.hcl` at the repository root:

```bash
cat ../backend.hcl
```

```hcl
resource_group_name  = "azure-terra-lab-tfstate-rg"
storage_account_name = "azureterralab7f3a1c"
container_name       = "tfstate"
use_azuread_auth     = false
```

If that file is missing, exercise0 has not been applied, and nothing below works.

## Initialise against the backend

There are two ways to configure a backend, and [`backend.tf`](backend.tf) has
both written out. Pick one.

### Option A — partial configuration (what the file does now)

`backend.tf` holds only the state key, because that is the only value unique to
this configuration. The other three come from `backend.hcl` at init time:

```bash
cd remote-backend-demo
terraform init -backend-config=../backend.hcl
```

### Option B — everything inline, so plain `terraform init` works

Comment out option A in [`backend.tf`](backend.tf), uncomment option B, and put
your own two names in it:

```bash
terraform -chdir=../exercise0 output state_resource_group_name
terraform -chdir=../exercise0 output storage_account_name
```

```hcl
terraform {
  backend "azurerm" {
    resource_group_name  = "azure-terra-lab-tfstate-rg"
    storage_account_name = "azureterralab7f3a1c"
    container_name       = "tfstate"
    key                  = "remote-backend-demo.tfstate"
  }
}
```

Then that is the whole command, with nothing outside this directory involved:

```bash
terraform init
```

Option B is the one to read first, because it shows the backend with nothing
hidden. Option A is what you move to once several roots share one storage
account, so a generated account name is written down once rather than copied by
hand into each of them. There is a third form, which is A with the values on the
command line instead of in a file:

```bash
terraform init \
  -backend-config="resource_group_name=azure-terra-lab-tfstate-rg" \
  -backend-config="storage_account_name=azureterralab7f3a1c" \
  -backend-config="container_name=tfstate"
```

### Either way, this is the line that matters

```
Initializing the backend...

Successfully configured the backend "azurerm"! Terraform will automatically
use this backend unless the backend configuration changes.
```

From here on every plan, apply, destroy and `state` command reads and writes the
blob in Azure, and your working directory holds no state at all.

**Try it wrong once, on purpose.** With option A active, run plain
`terraform init`. Terraform stops and prompts you for the backend values it is
missing rather than guessing, which is what "partial configuration" means: the
file is incomplete on purpose, and the rest arrives at init time.

## Apply it

```bash
terraform apply
terraform output
```

## Now prove where the state went

**There is no state file here.**

```bash
ls terraform.tfstate
# ls: cannot access 'terraform.tfstate': No such file or directory
```

**It is a blob in Azure.**

```bash
ACCOUNT=$(terraform -chdir=../exercise0 output -raw storage_account_name)

az storage blob list \
  --account-name "$ACCOUNT" \
  --container-name tfstate \
  --query "[].{name:name, size:properties.contentLength, modified:properties.lastModified}" \
  -o table
```

These `az storage` commands fetch the account key over ARM, which is what
exercise0's defaults allow. If you set `shared_access_key_enabled = false` there
is no key to fetch, so add `--auth-mode login` to each of them and the CLI signs
in as you instead.

```
Name                          Size    Modified
----------------------------  ------  -------------------------
remote-backend-demo.tfstate   3184    2026-09-18T12:04:11+00:00
```

**Terraform still reads it as if it were local.** The backend is transparent:
every command you already know works unchanged.

```bash
terraform state list
terraform show
```

## Watch the lock

The reason remote state exists is that more than one person can run Terraform.
Open two terminals in this directory. In the first:

```bash
terraform apply
```

and leave it sitting at the confirmation prompt. In the second:

```bash
terraform plan -lock-timeout=0
```

```
Error: Error acquiring the state lock

Error message: state blob is already locked
Lock Info:
  ID:        6f0a...
  Operation: OperationTypeApply
  Who:       dsagar@LAPTOP
  Created:   2026-09-18 12:06:33.6 +0000 UTC
```

Answer `no` in the first terminal and the second one runs. The azurerm backend
takes that lock as a **lease on the state blob itself**, so there is nothing else
to create — no lock table, unlike S3 and DynamoDB.

If a Terraform run is killed hard, the lease can outlive it. `terraform force-unlock <ID>`
releases it, and you should be certain no one else is mid-apply before you do.

## Watch the versioning

Exercise0 turned on blob versioning, so every apply keeps the previous state
rather than overwriting it. Uncomment the `archive` group in
[`terraform.auto.tfvars`](terraform.auto.tfvars), apply, and look again:

```bash
terraform apply

az storage blob list \
  --account-name "$ACCOUNT" --container-name tfstate --include v \
  --query "[?name=='remote-backend-demo.tfstate'].{version:versionId, current:isCurrentVersion}" \
  -o table
```

Each apply adds a version. That is your undo button for a state that got
corrupted or a `terraform state rm` you regret.

## Moving state that already exists

If you applied this directory with local state first, do not delete
`terraform.tfstate`. Add the backend block and let Terraform copy it up:

```bash
terraform init -backend-config=../backend.hcl -migrate-state   # option A
terraform init -migrate-state                                  # option B
```

```
Do you want to copy existing state to the new backend?
  Pre-existing state was found while migrating the previous "local" backend
  to the newly configured "azurerm" backend.
```

Answer `yes`, confirm the blob exists, then delete the local file and its backup.
The same command in reverse — comment out `backend.tf`, re-run with
`-migrate-state` — brings it back down.

## Tear it down

```bash
terraform destroy
```

Destroy removes the two resource groups. It does **not** remove the state blob;
it leaves an empty state behind, which is correct, because that blob is the
record of the fact that nothing is there any more.

## Worth knowing

**A backend block cannot interpolate anything.** No variables, no locals, no
outputs, no functions. Terraform has to configure the backend before it has
evaluated the configuration, so there is nothing to interpolate from. This fails:

```hcl
terraform {
  backend "azurerm" {
    key = "${var.environment}.tfstate"   # Error: Variables not allowed
  }
}
```

That single restriction is why `backend.hcl` and `-backend-config` exist at all,
and it is why `state_blob_name` in [`outputs.tf`](outputs.tf) repeats the key as
a literal instead of sharing one value with `backend.tf`.

**The key is what separates configurations, not the container.** One container
holds every root's state; each root picks its own key. Two roots that share a key
share a state file, and the second one to apply will plan to destroy everything
the first one built.

**`terraform init` is what binds a directory to a backend**, and the answer is
cached in `.terraform/`. Delete that directory and you have to init again. Change
any backend value and Terraform notices and asks what you want to do about it.

**State is still a secret.** It holds every attribute of every resource in
plaintext, including passwords and private keys. Remote state moves that file
somewhere with access control and encryption at rest instead of somewhere with
neither, but it does not make it safe to share.

**403 right after exercise0?** If you set `grant_current_user_blob_access = true`
there, the role assignment takes a minute or two to propagate. Wait, then run
`terraform init` again.

**Wrong subscription?** The backend finds the storage account using
`ARM_SUBSCRIPTION_ID`, the same variable the provider uses. If init reports the
account does not exist, that is usually what it means:

```bash
export ARM_SUBSCRIPTION_ID=$(az account show --query id -o tsv)
```

## Why this one is not numbered

`run.sh` treats every `exercise*` directory as one step in a chain and expects the
one before it to be applied first. This demo depends on exercise0 and on nothing
else, so numbering it would have the script report it as blocked by exercises it
does not need. Run it by hand, as above.
