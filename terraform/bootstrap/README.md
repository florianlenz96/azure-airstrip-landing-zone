## Bootstrap: Terraform state backend

Creates the storage account for the Terraform state in the management subscription. Run once with local state, then move the main configuration onto it.

```bash
cd terraform/bootstrap
terraform init
terraform apply -var management_subscription_id=<id> -var storage_account_name=<unique-name> -var principal_id=<your-object-id>

# Your user needs "Storage Blob Data Contributor" on the storage account.
# Set the storage account, resource group, container and Management subscription
# in the selected stage's backend.hcl, copied from backend.hcl.example.
```

Keep `bootstrap/terraform.tfstate` safe (it is git-ignored), or migrate it to the same container with its own key.

Then follow [Grass strip](../../grass_strip/README.md) or
[Regional airfield](../../regional_airfield/README.md). Both entry points use
the same platform backend key; policy modules have no separate state.

For an existing deployment, preserve its backend and state keys. If the platform
previously used local state, migrate it explicitly with `terraform init
-migrate-state` before switching roots. Subscriptions are created manually.
