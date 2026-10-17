# Airstrip

**Every airport started with a single strip.**

You have a field, a few aircraft, and your first arrivals on the way. You do not
need an international airport yet. You need somewhere to land.

Airstrip helps you build your Azure landing zone one expansion at a time:
prepare the ground, land your first applications, then add the infrastructure
your growing fleet actually needs. Your progress carries forward.

## Your flight path

```text
[1] Grass strip  ---------->  [2] Regional airfield  ---------->  [3] The long runway
    Land your first apps        Connect a growing fleet           Move toward ALZ / AVM
    Start here                  Expand when needed                Your next destination
```

No points for deploying everything on day one. Advance when your workloads need
the next capability, not because there is another level to unlock.

| Level | Mission briefing | What you unlock |
|---|---|---|
| **1. Grass strip** | [Land your first two or three apps](grass_strip/README.md) | Management groups, baseline policies, tags, central logging |
| **2. Regional airfield** | [Connect your growing fleet](regional_airfield/README.md) | The same foundation plus Connectivity, Firewall, hub/spoke networks, private DNS and Corp public-access Deny |
| **3. The long runway** | [Plan your next destination](#next-destination-the-long-runway) | A path toward the ALZ Accelerator or Azure Verified Modules, not another deployable stage |

**First time here? Open the [Grass strip guide](grass_strip/README.md).**
You only need that stage's guide and configuration to begin. The hangar full of
shared modules can wait.

## Mission 1: prepare for your first landing

**Objective:** deploy the shared foundation before bringing in your applications.

Collect the [prerequisites](#prerequisites), then
[bootstrap your state storage](terraform/bootstrap/README.md). From the repository
root:

```bash
az login
export ARM_SUBSCRIPTION_ID=<management-subscription-id>
cd grass_strip/terraform
cp backend.hcl.example backend.hcl
cp terraform.tfvars.example terraform.tfvars
# Edit backend storage details, subscription IDs, workloads and allowed regions.
terraform init -backend-config=backend.hcl
terraform validate
terraform plan -out=platform.tfplan
terraform apply platform.tfplan
```

Think of `validate` as your pre-flight inspection, `plan` as reviewing the flight
plan, and `apply` as authorizing the work.

**Milestone reached:** your platform foundation is in place. Next, deploy your
actual applications through their workload code; these commands do not create
the apps for you.

No wrapper, Python dependency, or custom deployment framework: just Terraform.
Each deployment root has its own `terraform.tfvars` and backend configuration.
These local files and saved plans are git-ignored. Applying the saved plan changes
real Azure resources and can incur costs.

## Mission 2: expand into a regional airfield

**Trigger:** your applications need private connectivity and centralized outbound
controls.

Keep your existing foundation. Switch to the Regional platform entry point using
the same platform backend, then configure and apply its hub and spoke roots.
Subscriptions are created manually; configure each workload subscription's
network using the reusable spoke root.

**Expansion unlocked:** hub/spoke networks, Azure Firewall, shared private DNS,
and Corp public-access restrictions. Your existing platform state carries
forward; this is an upgrade, not a second airport.

Before you authorize construction, read the
[Regional upgrade briefing](regional_airfield/README.md#upgrading-from-grass-strip).
Corp Deny becomes active in the Regional platform apply. Existing public
workloads need a migration plan and, where necessary, explicit expiring
exemptions. Changing the stage alone does not make those workloads private.

**Milestone reached:** configured spokes are deployed and peered. Before landing
production traffic, verify application integration, DNS resolution, allowed
traffic paths, and public-access settings in Azure.

## Airfield map

Stage folders are your departure gates. Shared modules are the construction
parts behind them. Workload folders are where the aircraft live.

```text
grass_strip/
  README.md
  terraform/                    # Grass-strip platform entry point
regional_airfield/
  README.md
  terraform/                    # Regional platform entry point, same platform state
    connectivity/               # Hub deployment
    spoke/                      # Reused for each manually created workload subscription
terraform/
  bootstrap/                    # One-time state storage
  modules/
    foundation/                 # Management groups, baseline policies, logging
    governance/                 # Tags, Corp restrictions, exemptions
    connectivity/               # Hub, Firewall, DNS
    spoke/                      # VNets, subnets, NSGs, routes, peering
  landingzones/                 # Workload infrastructure only
    corp/                       # e.g. hr-platform/ with RG, identity, VMs, PaaS
    online/                     # e.g. website/ with RG and static web app
```

The application folders shown above are examples of where real workloads belong,
not pre-created applications. See [workload ownership](terraform/landingzones/README.md).
There is no backend, policy deployment, or network deployment inside the
`landingzones/`, `corp/`, or `online/` grouping folders.

## Ground crew and aircraft: who owns what?

The **platform crew builds the airfield**. The **application teams bring the
aircraft**. In Terraform terms:

Both stage roots compose `module.foundation` and `module.governance`. Management
groups, logging, tag policies, Corp restrictions and exemptions share **one
platform state**, `management-groups.tfstate`. The two stages are alternative
entry points for that state, not independent installations.
Regional airfield reuses those shared modules; it does not import or apply the
Grass-strip deployment directory.

All networking belongs to the platform, including networks located in workload
subscriptions. Regional hub and per-subscription spoke states live under
`regional_airfield/terraform/`, not `landingzones/`. This supports arbitrary
manually created subscriptions without maintaining a provider alias for each one.
Bootstrap retains its initial state. There is no separate inventory stack.

Workload infrastructure can live under `terraform/landingzones/corp/<app>/` or
`terraform/landingzones/online/<app>/`, or in application repositories. Workloads
own their resource groups, identities, VMs/PaaS, private endpoints, application
VNet integration and service firewall rules. They consume platform network
outputs. Their deployment roots decide their workload lifecycle; platform applies
do not deploy applications or create subscriptions.

## Prerequisites

Your pre-flight kit:

- Terraform >= 1.7 and Azure CLI.
- Management-group, subscription-placement, policy/exemption and role-assignment
  permissions at the relevant scopes. Tenant-root Owner is a straightforward
  initial setup; prefer narrower delegated permissions where possible.
- Storage Blob Data Contributor on the existing state backend.
- A Management subscription. Regional airfield additionally requires Connectivity
  and manually created workload subscriptions, with network permissions in both
  Connectivity and every workload subscription.
- Diagnostic-setting access to the Management Log Analytics workspace.

Register `Microsoft.Security`, `Microsoft.OperationalInsights` and
`Microsoft.PolicyInsights` in Management. For Regional airfield register
`Microsoft.Network` and `Microsoft.Insights` in Connectivity/workload
subscriptions, and `Microsoft.PolicyInsights` where policies/remediation need it.
Workloads register their service providers. Registration is deliberately explicit:

```bash
az provider register --namespace Microsoft.Network --subscription <subscription-id>
```

Apply in dependency order: platform, hub, then spokes. Terraform locks individual
states, not an entire multi-state operation. Serialize changes to the shared hub.

## Tower rules: guardrails, not autopilot

Both stages retain the ALZ-style hierarchy: Airstrip root, Platform with
Management/Identity, Landing Zones with Corp/Online and configured workload groups,
Sandbox and Decommissioned. Connectivity exists only in Regional airfield.

Baseline policies restrict locations, require resource-group tags `owner`,
`cost-center` and an allowed `env`, inherit missing resource tags, and configure
supported diagnostics/Activity Logs to central Log Analytics. Default retention
is 30 days. Existing resources need explicit remediation for Modify and
DeployIfNotExists policies. Paid Defender plans remain opt-in and Management-only.

Regional airfield assigns **Deny in Corp only** for covered public endpoints:
Storage accounts, Key Vault vaults (with built-in recovery behavior), Azure SQL
logical servers, App Service/Function sites covered by Microsoft's built-ins,
Cosmos DB database accounts, and NIC public-IP attachments. Online/platform are
outside this initiative. This is not blanket coverage of every Azure service,
deployment slot, hosting-environment exception, frontend or public IP resource.

The [built-in definitions](https://github.com/Azure/azure-policy/tree/master/built-in-policies/policyDefinitions)
are supplemented by a strict Storage rule requiring public network access to be
`Disabled` (not `SecuredByPerimeter`). The initiative retains its old parameter
schema, but Regional airfield always assigns Deny;
there is no global Audit/Disabled switch. Explicit expiring exemptions are
described in the [Regional guide](regional_airfield/README.md#exemptions).

Deny does not retrofit private endpoints or disable existing public access.
Creating private endpoints also does not disable public access. Plan workload
migrations and scoped exemptions before upgrading. Firewall is an egress-control
layer, not a WAF or a guarantee that every private/service traffic path is
inspected; see the [network boundaries](regional_airfield/README.md#subnets-and-traffic).

## Already airborne? Keep your flight log

Start with a fresh deployment; migration from earlier repository layouts is not
supported. The Grass strip-to-Regional upgrade keeps the same platform state and
module addresses.

The [Regional guide](regional_airfield/README.md) covers stage upgrades, onboarding,
costs and explicit network decommissioning. With native Terraform, reviewing plans,
keeping subscription configurations complete, and coordinating state changes are
the operator's responsibility.

## Maintenance bay: local checks

```bash
terraform fmt -check -recursive terraform grass_strip regional_airfield
terraform -chdir=grass_strip/terraform init -backend=false
terraform -chdir=grass_strip/terraform validate
terraform -chdir=grass_strip/terraform test
```

Initialize deployable roots with `init -backend=false` for local `validate`.
Native Terraform tests in the stage roots and shared modules use mocked providers;
`spoke` receives its aliased provider through the caller, so validate its deployment
root rather than validating that child module standalone.
Mocks do not prove live Azure routing, permissions or PaaS/policy rollout.
Verify those in a separately authorized Azure environment before production use.

## Next destination: the long runway

Your village airfield now serves more teams, more applications, and more demanding
routes. Eventually, it needs a longer runway.

Virtual WAN, complex identity, subscription vending, and multi-region designs
are signals to explore the [ALZ Accelerator](https://aka.ms/alz) or
[Azure Verified Modules](https://aka.ms/avm). Airstrip's hierarchy gives you a
familiar starting point, not an automatic migration.

**This destination is not a deployable Airstrip level.** Only `grass_strip` and
`regional_airfield` are accepted stage values today.

## Join the ground crew

Found a pothole in the runway? Have a clearer flight plan? Issues and pull
requests are welcome.

Keep the core idea in mind: **simple first**. Every addition should help the next
engineer land their first workload, not require them to learn airport management
before they can start.

## License

[MIT](LICENSE)
