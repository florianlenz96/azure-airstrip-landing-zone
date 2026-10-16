## Bootstrap: Terraform state backend

Creates the storage account for the Terraform state in the management subscription. Run once with local state, then move the main configuration onto it.

```bash
cd terraform/bootstrap
terraform init
terraform apply -var management_subscription_id=<id> -var storage_account_name=<unique-name>

# Your user needs "Storage Blob Data Contributor" on the storage account.
# Copy the backend_config output into terraform/platform/backend.tf, then:
cd ../platform
terraform init -migrate-state
```

Keep `bootstrap/terraform.tfstate` safe (it is git-ignored), or migrate it to the same container with its own key.
