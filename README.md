# Airstrip

**Every airport started with a single strip.**

Land your first workloads on Azure today. Extend the runway as you grow, all the way to the Azure Landing Zone Accelerator.

🌐 [airstrip.cloud](https://airstrip.cloud)

## The idea

No airport was built in one go. It starts as a village airfield with one short strip. Then the strip gets longer, a tower is added, a second taxiway. One day you have a 2.5 km runway that can take anything.

Airstrip is that village airfield for Azure. It gives you a real landing zone with management groups, policies, logging and networking, in a handful of files you can read and understand in an afternoon.

It is built for two kinds of teams:

- **Teams just getting started**, who want to migrate their first two or three apps, run a proof of concept or simply learn how a landing zone works.
- **Teams planning for the long run**, who want a clean foundation today and a clear path to the Azure Landing Zone Accelerator or Azure Verified Modules (AVM) tomorrow.

## Design principles

- **Few files, little effort.** Every module does one thing. No wrappers, no bootstrapping, no hidden logic.
- **Readable over clever.** If a line needs a comment to be understood, it gets simplified first.
- **ALZ-compatible by design.** Management group names, hierarchy and policy choices follow the Cloud Adoption Framework conventions. When you outgrow Airstrip, you migrate instead of starting over.

## Extending the runway

| Stage | Runway | Built for | What it adds |
|-------|--------|-----------|--------------|
| 1 | **Grass strip** | First 2–3 apps, proofs of concept, learning | Management group hierarchy, baseline policies, central logging |
| 2 | **Regional airfield** | Several teams, first production workloads | Hub network with peering, Defender for Cloud, extended policy set |
| 3 | **2.5 km runway** | A growing platform with many teams | Ready for take-off to the ALZ Accelerator or AVM |

Start with stage 1. Move on only when you need to.

## What's included

### Management groups

The same structure as the Azure Landing Zone reference architecture, so nothing has to be renamed later:

```
Tenant Root Group
└── airstrip
    ├── platform
    │   ├── management
    │   ├── connectivity
    │   └── identity
    ├── landingzones
    │   ├── corp
    │   │   └── <workload MGs>
    │   └── online
    │       └── <workload MGs>
    ├── sandbox
    └── decommissioned
```

Everything is Terraform and lives in `terraform/`, in folders that mirror the management group hierarchy. Each folder is its own stack with its own state. Workload groups under `corp` and `online` come from the `workloads` variable in `platform/`.

```bash
cd terraform/platform
cp terraform.tfvars.example terraform.tfvars   # edit root_id, workloads, subscriptions
terraform init && terraform apply
```

See [Repository structure](#repository-structure) for the apply order.

### Policies

A small, curated set of built-in policies. Built-in only (plus two tiny wrappers), so you always know what is being enforced.

| Scope | Policy | Effect |
|-------|--------|--------|
| `airstrip` | Allowed locations and resource group locations (`allowed_locations`) | Deny |
| `airstrip` | Diagnostic settings (allLogs) and Activity Log to the central workspace | DeployIfNotExists |
| `landingzones` | Resource groups need tags `owner`, `cost-center`, `env` (`env` in `allowed_envs`) | Deny |
| `landingzones` | Resources inherit `owner`, `cost-center`, `env` from their resource group | Modify |
| `corp` | No public endpoints for Storage, Key Vault, SQL, App Service, Functions, Cosmos DB, NIC public IPs (`public_endpoints_effect`) | Audit, switch to Deny |

Policies with DeployIfNotExists/Modify run with a managed identity. They apply to new resources right away. Existing resources need a remediation task in the portal.

The providers `Microsoft.Security`, `Microsoft.OperationalInsights` and `Microsoft.PolicyInsights` must be registered in the management subscription (`az provider register --namespace <name>`).

### Logging

A central Log Analytics workspace (`log-airstrip`, 30 days retention) in the management subscription that all subscriptions report to.

### Defender for Cloud

Foundational CSPM is free and always on. Servers, Storage, Key Vault and ARM plans are off by default and switched on with `defender_plans`. They only apply to the management subscription for now.

### Network

A hub virtual network in the connectivity subscription, with subnets prepared for firewall, bastion and gateway. Spokes peer to the hub.

## What's not included (on purpose)

Virtual WAN, multi-region setups, automated subscription vending and complex identity designs. These belong on the long runway. When you need them, it is time for the next step.

## Prerequisites

- Azure CLI with Bicep (`az bicep install`)
- Owner permissions on the tenant root management group ([how to elevate access](https://learn.microsoft.com/azure/role-based-access-control/elevate-access-global-admin))
- At least one subscription. Two or three (management, connectivity, workloads) are recommended.

## Quick start

```bash
# 1. Clone the repo
git clone https://github.com/<your-org>/airstrip.git
cd airstrip

# 2. Log in
az login

# 3. Adjust the parameters
#    Edit main.bicepparam (prefix, location, subscription IDs, address space, tags)

# 4. Deploy
az deployment tenant create \
  --location westeurope \
  --template-file main.bicep \
  --parameters main.bicepparam
```

## Repository structure

```
terraform/
├── bootstrap/               # 0. State storage account (local state, run once)
├── platform/                # 1. Management groups, subscription placement, root policies
│   └── management/          #    Local module: Log Analytics, Defender, diagnostic settings
└── landingzones/            # 2. Required tags for corp + online
    └── corp/                # 3. No public endpoints
```

Run the stacks in this order with `terraform init && terraform apply`. `platform/` is one stack and calls its subfolders as local modules, so one apply covers the management groups and everything under `platform`. Each stack has a `terraform.tfvars.example`. Later stacks look up the management groups by name (`<root_id>-corp`), so they only need the same `root_id`. The `platform/` stack applies to the subscription in `ARM_SUBSCRIPTION_ID`, which must be the management subscription.

## Ready for take-off

When your platform grows to many teams, many subscriptions or strict compliance requirements, it is time to move to the [Azure Landing Zone Accelerator](https://aka.ms/alz) or [Azure Verified Modules](https://aka.ms/avm). Because Airstrip follows the same hierarchy and conventions, your existing management groups and subscriptions fit into the target architecture, and your team already knows the concepts.

## Contributing

Issues and pull requests are welcome. Please keep the core idea in mind: **simple first**. New features should make Airstrip more useful without making it harder to understand.

## License

[MIT](LICENSE)
