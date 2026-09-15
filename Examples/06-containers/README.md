# 06: Container Registry, Container Apps and AKS

The default creates a Basic ACR registry, a VNet-integrated Container Apps environment, a runnable public sample container, a pull identity, NAT egress and Log Analytics. The sample image starts independently of the empty ACR; the registry connection is ready for images you publish later.

## Default Demonstration

After deployment, `container_app_url` exposes the sample over HTTPS. The app scales from zero to three replicas using an HTTP rule and has readiness/liveness probes. The public sample image uses a mutable tag for demonstration; pin a reviewed digest for production.

Basic ACR has an authenticated public endpoint and disables shared administrator credentials. A private ACR deployment needs Premium, registry private endpoints and correct DNS. A private Kubernetes API does not imply that its image registry is private.

## Optional AKS

Set `enable_aks = true` and provide existing `aks_admin_group_object_ids`. This creates a private cluster with local accounts disabled, Entra RBAC, CNI overlay/Cilium, workload identity/OIDC, a Key Vault CSI provider, autoscaling system nodes and Container Insights integration.

The control-plane identity receives Network Contributor on the VNet so AKS can manage its private DNS link. A separate kubelet identity receives AcrPull, with Managed Identity Operator granted to the control-plane identity. The cluster uses the explicitly attached NAT gateway.

AKS Free is a control-plane pricing choice; nodes, disks, networking and logs still cost money. No Kubernetes workload or federated workload-identity credential is created. A connected client with DNS access, `kubectl`, `kubelogin` and the correct Entra permissions is required for cluster administration. Kubeconfig credentials are deliberately not exported as Terraform outputs.

## Validate

```bash
bash scripts/validate.sh 06-containers
```

Tests cover both the Container Apps baseline and the private AKS option. See [Docs/DEPLOYMENT.md](../../Docs/DEPLOYMENT.md) before provisioning.