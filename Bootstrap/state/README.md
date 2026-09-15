# Separate Terraform State Bootstrap

Creates a dedicated resource group, ZRS StorageV2 account, versioned/soft-delete-protected `tfstate` container, scoped Entra writer roles and a CanNotDelete storage lock. It uses local state initially because a backend must exist before Terraform can initialize it.

The storage public endpoint is restricted to explicitly supplied runner addresses. This is suitable for a controlled demo workstation or fixed-egress runner. A production private backend requires a private endpoint, DNS and a connected runner; it cannot be reached automatically from public GitHub-hosted jobs.

## Required Inputs

Replace the documentation placeholders in [terraform.tfvars.example](terraform.tfvars.example) before a real deployment:

- `runner_public_ip_addresses`: actual approved public egress IPv4 addresses/CIDRs. Supply a single IP as a bare address, not `/32`.
- `state_principals`: existing operator/runner object IDs and principal types. Include the operator who will initialize the backend. No identity is created by this bootstrap.
- `prefix` and `location`: naming and a region that supports ZRS.

The deployer needs resource creation, scoped role-assignment and lock permissions. Backend users require Storage Blob Data Contributor on the container and a permitted network path; Contributor on the resource group alone is not the same thing.

## Validate Without Azure

From the project root:

```bash
bash scripts/validate.sh state
```

## Bootstrap Deliberately

Complete [Docs/DEPLOYMENT.md](../../Docs/DEPLOYMENT.md), configure real inputs and obtain approval before these commands:

```bash
terraform -chdir=Bootstrap/state init
terraform -chdir=Bootstrap/state plan -out=state.tfplan
terraform -chdir=Bootstrap/state apply state.tfplan
```

Protect this bootstrap's local state separately. Keep it out of Git, retain a secure recovery copy and do not destroy the bootstrap while any workload depends on its backend.

## Configure One Example's Backend

Use [Templates/backend.tf.example](../../Templates/backend.tf.example) as an additional backend declaration in the selected example, and [Templates/backend.hcl.example](../../Templates/backend.hcl.example) for its non-secret settings. Fill in the bootstrap outputs for account/group/container and choose a unique key such as `demo/01-network-foundation.tfstate`.

After creating the backend configuration locally in that example, initialize it:

```bash
terraform -chdir=Examples/01-network-foundation init -backend-config=backend.hcl
```

If migrating an existing local state, take a protected backup first and use `init -migrate-state -backend-config=backend.hcl`, review the prompt and verify the destination. Do not use `-reconfigure` to pretend an existing state was migrated. Never reuse one backend key for unrelated examples or environments.

Allow Entra role propagation before first backend access. `features.storage.data_plane_available = false` affects provider provisioning probes, **not** the backend's need to read/write the actual state blob.

## Lock and Retention Caveats

Terraform uses a blob lease for concurrent state locking. The Azure management lock helps prevent accidental resource deletion but can itself be removed by an authorized Terraform plan; it is not an unconditional destroy guard. Versioning/soft deletion do not replace a tested state recovery procedure. Retire or migrate every dependent state before considering backend cleanup.