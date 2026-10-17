# Regional airfield

**Mission: connect a growing fleet without replacing your first runway.**

This stage shares Grass strip's foundation/governance modules, adds Connectivity,
and provides hub and spoke deployment roots. Corp public access is denied for
covered services unless explicitly exempted. Online is outside that policy.

## Your construction order

| Terraform root | Purpose | State key |
|---|---|---|
| `terraform/` | Foundation, logging, tags, Corp policies/exemptions | `management-groups.tfstate` |
| `terraform/connectivity/` | Hub, Firewall, shared DNS, diagnostics | `connectivity.tfstate` |
| `terraform/spoke/` | One manually created subscription's network | `network-<subscription-id>.tfstate` |

Apply **platform, hub, then each spoke**. These are platform/network states, not
workload grouping states. Terraform >= 1.7 and Azure CLI are sufficient; there is
no runner, inventory service or Python dependency.

### 1. Extend the foundation

After the [prerequisites](../README.md#prerequisites) and
[bootstrap](../terraform/bootstrap/README.md), from the repository root:

```bash
az login
export ARM_SUBSCRIPTION_ID=<management-subscription-id>
cd regional_airfield/terraform
cp backend.hcl.example backend.hcl
cp terraform.tfvars.example terraform.tfvars
# Edit IDs, backend details, regions, subscription mappings and exemptions.
terraform init -backend-config=backend.hcl
terraform validate
terraform plan -out=platform.tfplan
terraform apply platform.tfplan
terraform output -raw log_analytics_workspace_id
```

For an upgrade, use your existing backend and platform variables rather than
overwriting them with examples. Corp Deny takes effect in this apply; read the
[upgrade briefing](#upgrading-from-grass-strip) first.

### 2. Build the hub

The following commands start from `regional_airfield/terraform/`:

```bash
cp connectivity/terraform.tfvars.example connectivity/terraform.tfvars
# Set Connectivity subscription, CIDRs, tags, DNS zones and explicit outbound rules.
# Set log_analytics_workspace_id to the platform output printed above.
terraform -chdir=connectivity init -backend-config=../backend.hcl \
  -backend-config=key=connectivity.tfstate
terraform -chdir=connectivity validate
terraform -chdir=connectivity plan -out=hub.tfplan
terraform -chdir=connectivity apply hub.tfplan
terraform -chdir=connectivity output -json spoke_inputs > spoke/hub.tfvars.json
```

The hub provider uses the Connectivity subscription from its variables; its
backend remains in Management. The exported JSON contains a `hub` input object,
so it is a native Terraform var file, not a script-generated configuration.
Re-export it after hub changes before planning spokes.

### 3. Connect a workload subscription

Create subscriptions manually, register providers and grant permissions. Add the
subscription to the platform's `subscriptions` map and apply the platform.
Then, from `regional_airfield/terraform/`:

```bash
cp spoke/terraform.tfvars.example spoke/erp.tfvars
# Edit erp.tfvars: subscription, name, location, tags, CIDRs, subnets and NSG rules.
terraform -chdir=spoke init -reconfigure -backend-config=../backend.hcl \
  -backend-config=key=network-33333333-3333-4333-8333-333333333333.tfstate
terraform -chdir=spoke validate
terraform -chdir=spoke plan -var-file=erp.tfvars -var-file=hub.tfvars.json \
  -out=erp.tfplan
terraform -chdir=spoke apply erp.tfplan
terraform -chdir=spoke output -json network
```

Replace the example ID in the backend key with the actual subscription ID.
Create one named var file per subscription and repeat with its matching key.
**Always pair the right var file with the right state.** Do not create an
auto-loaded `spoke/terraform.tfvars`: explicit per-subscription files avoid leaking
one team's settings into another deployment.

Adding a subscription ID to the platform map **does not create its network**.
Apply the spoke root for that subscription; the module creates its subnets,
NSGs, routes, DNS links and both peering directions. Platform networking stays
here, not in `terraform/landingzones/`.

Keep non-overlapping CIDRs across every hub/spoke. When adding spokes, update
`other_spoke_prefixes` in the affected spoke var files and reapply them so
inter-spoke routes stay current. Maintain the firewall rules separately.
Terraform has no global cross-state address-allocation or inventory validation.

## Subnets and traffic

Use RFC1918 IPv4 space. The firewall subnet must be `/26` or larger; choose
service-appropriate workload subnet sizes. Check VNet containment and all overlaps
before applying. Every subnet receives an NSG and UDR.

NSGs reserve priority 100 for Firewall DNS and 4096 for default Deny controls.
Configure explicit inbound/private-outbound rules at priorities 200-4000.
The example permits HTTPS between the app and private-endpoint subnets; configure
other ports your services require. `private_endpoints = true` enables NSG
enforcement and cannot be combined with delegation. Service-specific delegations,
ports, and subnet-size requirements are the operator's responsibility.

Default Internet routes and configured other-spoke routes use Azure Firewall.
Both peering directions allow forwarded traffic. Inter-spoke access also needs
explicit NSG and Firewall rules; peering alone is not transitive.

Firewall Standard has explicit outbound rules, threat-intelligence Deny,
DNS proxy and central diagnostics. No configured allow rules means no permitted
workload egress through it. Spokes use Firewall for DNS; the hub's links resolve
shared private zones through Azure-provided DNS.

Workloads consume the `network` output: VNet/subnet IDs, private DNS zone IDs and
DNS servers. App code creates private endpoints/DNS zone groups, configures VNet
integration and disables public access. Private endpoints do not automatically
disable public access. PaaS egress needs supported outbound integration/route-all.
Private-endpoint traffic can remain direct/private with NSG controls and is
**not guaranteed to traverse Firewall**.

Firewall is not a WAF. Public Online apps may need one. VPN, Bastion, gateways,
Virtual WAN, TLS inspection and multi-region recovery are outside this setup.
Costs include Firewall, its public IP, private DNS, logs and applicable peering
traffic. Workload private endpoints have separate charges. Paid Defender plans
remain opt-in and Management-only.

## Upgrading from Grass strip

Copy the existing platform variables and `backend.hcl` to this root. Keep the same
root ID, subscription mappings, backend account/container and platform state key.
Regional defaults select the new stage; if your old tfvars explicitly set
`stage = "grass_strip"`, remove it or change it to `regional_airfield`.
Do not apply both stage roots as independent platforms.

Before the Regional platform apply, approve narrow expiring exemptions for public
Corp resources that cannot yet migrate. Then deploy platform/hub/spokes, create
private connectivity in app code, verify it, disable public access, and remove the
exemptions through another platform apply.

Deny does not retrofit existing services. Assignment updates and exemption
creation are not atomic; coordinate workload changes during rollout.

## Exemptions

Set the platform `exemptions` map using the shape in
[exemption.json.example](terraform/exemption.json.example). Merge the example entry
into that map; replace its expiry with a future RFC3339 timestamp.
Each exemption needs a scope, justification, expiry, optional Waiver/Mitigated
category, and optional `reference_ids`.

References: `storage`, `key_vault`, `sql_database`, `app_service`, `function_apps`,
`cosmos_db`, `nic_public_ip`. Empty references waive the full initiative at that
scope; prefer resources and specific references. Function exceptions may need both
App Service and Function references. Use only Corp scopes; Azure checks assignment
scope compatibility. Remove or explicitly renew expired exemptions.

## Review before take-off

There is no wrapper blocking deletions, stage downgrades, forgotten subscriptions
or stale output files. Review saved plans, keep backups and a record of each
subscription's var file/state key. Serialize changes to shared hub resources;
Terraform only locks individual states.

Decommission workloads/private endpoints first. Use the same spoke backend key
and both var files with `terraform plan -destroy -out=destroy.tfplan`, review it,
then explicitly apply that plan. Remove subscription associations/exemptions in
the platform separately. Destroy spokes before the hub; never remove state to
pretend infrastructure has been decommissioned.
