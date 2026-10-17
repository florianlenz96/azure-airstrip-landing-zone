# Migrating the earlier layout

Fresh deployments do not need this procedure. No scripts or automatic migration
are provided. Use Terraform's native state commands in a reviewed maintenance
window; state can contain sensitive data.

## Addresses within an existing state

Both stage roots use `management-groups.tfstate`. Their moved blocks transfer
the original platform addresses under `module.foundation`. Hub and spoke keys
stay `connectivity.tfstate` and `network-<subscription-id>.tfstate`; moved blocks
transfer their resources under `module.connectivity` and `module.spoke`.
These moves must show as address changes, not Azure resource replacements.

Use Regional airfield for an existing full hierarchy containing Connectivity.
Keep original backend details and configuration. Initialize the new root against
that same state key, plan, and review before applying.

## Consolidating old policy states

Old `landingzones.tfstate` (tags) and `landingzones-corp.tfstate` (Corp restrictions)
must be combined into the platform state before any new-layout apply. Moved blocks
cannot move objects between different remote states. Never leave the same Azure
object managed by two active deployment roots.

Stop all writers/CI for all affected states. Back up current snapshots using
`terraform state pull` from the old roots or download their versioned blobs.
Keep untouched originals in a secure location outside the repo. Perform the
following operations in a separate directory with **no configured backend**.

For each managed resource in the old tag/Corp snapshots, use native local state
transfer. For example:

```bash
terraform state mv \
  -state=/secure/working/tags.tfstate \
  -state-out=/secure/working/platform.tfstate \
  'azurerm_management_group_policy_assignment.require_tag' \
  'module.governance.azurerm_management_group_policy_assignment.require_tag'
```

Use working copies, not your untouched backups. Whole-resource moves preserve
count/for_each instance keys. Repeat for all tag resources:

| Type | Name |
|---|---|
| `azurerm_management_group_policy_assignment` | `require_tag`, `require_env`, `inherit_tag` |
| `azurerm_policy_definition` | `env_tag_values` |
| `azurerm_role_assignment` | `inherit_tag` |

Repeat from the Corp state for all resources present:

| Type | Name |
|---|---|
| `azurerm_policy_set_definition` | `no_public_endpoints` |
| `azurerm_management_group_policy_assignment` | `no_public_endpoints` |
| `azurerm_policy_definition` | `storage_private_only` |
| `azurerm_subscription_policy_exemption` | `this` |
| `azurerm_resource_group_policy_exemption` | `this` |
| `azurerm_resource_policy_exemption` | `this` |

Each destination is `module.governance.<type>.<name>`. Original unindexed Corp
resources are subsequently handled by the module's moved blocks. Data lookups
can remain in the old snapshots; no managed policy resources should remain.
Stop if unexpected resources or existing destination owners are found.

Review `terraform state list -state=<working-snapshot>` for all three snapshots.
Publish the prepared platform snapshot with `terraform state push` after
initializing the selected stage root against `management-groups.tfstate`.
Then reinitialize against each legacy key and push its corresponding emptied
snapshot. Restore the platform key before planning or applying.

For example, from the selected stage directory:

```bash
terraform init -reconfigure -backend-config=backend.hcl
terraform state push /secure/working/platform.tfstate
terraform init -reconfigure -backend-config=backend.hcl \
  -backend-config=key=landingzones.tfstate
terraform state push /secure/working/tags.tfstate
terraform init -reconfigure -backend-config=backend.hcl \
  -backend-config=key=landingzones-corp.tfstate
terraform state push /secure/working/corp.tfstate
terraform init -reconfigure -backend-config=backend.hcl
```

Never apply while pointed at a legacy key. Do not use `state push -force` to
bypass lineage/serial errors. A cross-state transfer is not atomic: keep writers
stopped until all snapshots are published and reviewed. If interrupted, finish
or restore the whole set through your reviewed recovery process.

Preserve the old settings in the new native `terraform.tfvars`. Plan the platform
and networks; verify no unexpected deletions/replacements before applying.
Retire old deployment jobs so they cannot recreate duplicate owners. Keep secure
backups according to your recovery policy.

## Removed orchestration

The Python runner, shared JSON configuration and inventory root are removed.
Configure each root using its `terraform.tfvars.example` and explicit backend key.
Export the hub input using `terraform output -json spoke_inputs` as described in
the Regional guide. The old inventory state contains only `terraform_data`; retain
it as an archive if it was used. No Azure resource depends on it.
