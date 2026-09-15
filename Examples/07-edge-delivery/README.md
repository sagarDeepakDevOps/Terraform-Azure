# 07: Front Door, WAF and Traffic Delivery

**High-cost lab.** The default creates Front Door Premium with managed WAF in Prevention mode, a Linux Web App origin restricted to this Front Door instance, and an example public DNS zone.

## Default Flow

Use `front_door_url` for the Azure-managed HTTPS hostname. HTTP redirects to HTTPS; the origin is also contacted using HTTPS and its matching host header. The origin restriction combines `AzureFrontDoor.Backend` with the profile's `X-Azure-FDID` value, not just the broad service tag.

Deploy a healthy web application before treating the origin/Front Door endpoint as a working application. This Terraform lab creates hosting, not the origin's application code.

The default DNS zone is a reserved example domain. Creating an Azure DNS zone does not register/delegate a real domain. A CNAME also does not complete Front Door custom-domain ownership validation or certificate binding. Use the default Front Door hostname until those steps are complete.

## Optional Independent Comparisons

Application Gateway is enabled with `enable_application_gateway`. It requires a real base64 PFX, its password, a matching listener hostname and reachable HTTPS `gateway_backend_hostnames`. The PFX/private key is sensitive and retained in state. Production should integrate Key Vault certificate references. Do not use the Front-Door-restricted origin as this independent gateway's backend without redesigning access restrictions.

Traffic Manager is enabled by supplying at least two `traffic_manager_endpoints` with unique priorities. It performs DNS routing, not HTTP proxying or TLS termination. The endpoints must be separately deployed, healthy applications with the client-facing hostname/certificate configured. The lab does not create a multi-region application just by creating a Traffic Manager profile.

The mock certificate and example hostnames in tests intentionally do not represent real TLS material or production origins.

## Validate

```bash
bash scripts/validate.sh 07-edge-delivery
```

Tests cover the default WAF and both optional delivery services. Read [Docs/DEPLOYMENT.md](../../Docs/DEPLOYMENT.md) and [Docs/SECURITY-AND-COST.md](../../Docs/SECURITY-AND-COST.md) before deployment.