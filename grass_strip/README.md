# Grass strip

**Mission: land your first applications without building an international airport.**

This stage deploys management groups (without Connectivity), baseline policies,
required tags, central logging, and opt-in Management subscription Defender plans.
No VNets, Firewall, or Corp public-endpoint restriction.

## Prepare the ground

You need Terraform >= 1.7, Azure CLI, and the
[platform permissions](../README.md#prerequisites). First
[bootstrap state storage](../terraform/bootstrap/README.md).

From the repository root:

```bash
az login
export ARM_SUBSCRIPTION_ID=<management-subscription-id>
cd grass_strip/terraform
cp backend.hcl.example backend.hcl
cp terraform.tfvars.example terraform.tfvars
# Edit both files: backend account/subscription, subscription mappings and regions.
terraform init -backend-config=backend.hcl
terraform validate
terraform plan -out=platform.tfplan
terraform apply platform.tfplan
```

**First landing complete:** the foundation is ready for workload deployments.
Terraform commands are the interface; no scripts or extra runtime are required.
Local `backend.hcl`, `*.tfvars`, and saved plans are git-ignored.

## Know your airfield

`main.tf` calls shared foundation and governance modules. Management groups,
logging and all policy resources share one state, `management-groups.tfstate`.
There is no separate tag-policy or Corp-policy state.

Add actual workload code under `terraform/landingzones/corp/<app>/` or
`terraform/landingzones/online/<app>/`, or in its application repository.
Workloads own their RGs, identities, VMs/PaaS and service firewall settings.
These platform commands do not create apps or subscriptions.

Review every plan. Terraform has no deployment-wide inventory checking for
removed subscriptions, stage downgrades or forgotten network states. Back up state
and keep configuration files for every deployment.

## Unlock Regional airfield

Use [Regional airfield](../regional_airfield/README.md#upgrading-from-grass-strip)
when private networking is needed. Copy your platform variables and backend into
the Regional root, keep the **same state key**, and initialize it there.
Both roots retain the same module addresses; do not apply them independently.

Existing installations from the earlier layout need the
[state migration procedure](../docs/state-migration.md) before applying.
