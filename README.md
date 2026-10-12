# Azure Airstrip (Landing Zone)

**Your Azure landing zone, without the airport.**

Airstrip is a lightweight starting point for Azure landing zones. Instead of a complex framework, you get a focused repo with the essentials every Azure environment needs: governance through policies, central logging and a solid network foundation.

Readable code over layers of abstraction. Start small, understand every line, and expand as you grow.

🌐 [airstrip.cloud](https://airstrip.cloud)

## Why Airstrip?

The official Azure Landing Zone Accelerator and Azure Verified Modules are powerful, but they come with a steep learning curve: bootstrapping, many layers of modules, and a lot of configuration before you deploy anything.

Airstrip takes the opposite approach:

- **Small** – a handful of files you can read in an afternoon
- **Transparent** – no hidden logic, no wrapper modules
- **Extendable** – a clean base you can grow, not a black box you have to work around

## What's included

| Area       | What you get                                                        |
|------------|---------------------------------------------------------------------|
| Governance | Baseline Azure Policy assignments (allowed regions, required tags)  |
| Logging    | Central Log Analytics workspace with diagnostic settings            |
| Network    | Hub virtual network with subnets ready for firewall and bastion     |
| Security   | Microsoft Defender for Cloud baseline configuration                 |

## What's not included (on purpose)

Multi-region setups, Virtual WAN, subscription vending and complex management group hierarchies. If you need those, you have probably outgrown Airstrip, and that's fine. See [Growing beyond Airstrip](#growing-beyond-airstrip).

## Prerequisites

- An Azure subscription with **Owner** permissions
- [Azure CLI](https://learn.microsoft.com/cli/azure/install-azure-cli) with Bicep (`az bicep install`)

## Quick start

```bash
# 1. Clone the repo
git clone https://github.com/<your-org>/airstrip.git
cd airstrip

# 2. Log in and select your subscription
az login
az account set --subscription "<subscription-id>"

# 3. Adjust the parameters
#    Edit main.bicepparam (prefix, location, address space, tags)

# 4. Deploy
az deployment sub create \
  --location westeurope \
  --template-file main.bicep \
  --parameters main.bicepparam
```

## Repository structure

```
airstrip/
├── main.bicep            # Entry point, wires the modules together
├── main.bicepparam       # Your configuration
└── modules/
    ├── governance.bicep  # Policy assignments
    ├── logging.bicep     # Log Analytics workspace
    ├── network.bicep     # Hub virtual network
    └── security.bicep    # Defender for Cloud
```

## Growing beyond Airstrip

Airstrip is designed as a first step. When your environment grows to multiple teams, many subscriptions or strict compliance requirements, take a look at the [Azure Landing Zones Accelerator](https://aka.ms/alz). The concepts you learned here map directly to it.

## Contributing

Issues and pull requests are welcome. Please keep the core idea in mind: **simple first**. New features should make Airstrip more useful without making it harder to understand.

## License

[MIT](LICENSE)
