terraform {
  required_version = ">= 1.5"

  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 4.0"
    }
  }
}

provider "azurerm" {
  features {}
  subscription_id                 = var.management_subscription_id
  resource_provider_registrations = "none"
  storage_use_azuread             = true
}

variable "management_subscription_id" {
  description = "ID of the management subscription that hosts the state."
  type        = string
}

variable "principal_id" {
  description = "Principal ID for the role assignment to the storage account."
  type        = string
}

variable "location" {
  type    = string
  default = "westeurope"
}

variable "storage_account_name" {
  description = "Globally unique, 3-24 lowercase letters and digits."
  type        = string
}

resource "azurerm_resource_group" "state" {
  name     = "rg-airstrip-tfstate"
  location = var.location
}

resource "azurerm_storage_account" "state" {
  name                            = var.storage_account_name
  resource_group_name             = azurerm_resource_group.state.name
  location                        = azurerm_resource_group.state.location
  account_tier                    = "Standard"
  account_replication_type        = "GRS"
  min_tls_version                 = "TLS1_2"
  allow_nested_items_to_be_public = false
  shared_access_key_enabled       = false

  blob_properties {
    versioning_enabled = true

    delete_retention_policy {
      days = 30
    }
    container_delete_retention_policy {
      days = 30
    }
  }
}

resource "azurerm_role_assignment" "storage_blob_contributor" {
  principal_id         = var.principal_id
  role_definition_name = "Storage Blob Data Contributor"
  scope                = azurerm_storage_account.state.id
}

resource "azurerm_storage_container" "state" {
  name                  = "tfstate"
  storage_account_id    = azurerm_storage_account.state.id
  container_access_type = "private"
}

output "backend_config" {
  value = <<-EOT
    terraform {
      backend "azurerm" {
        resource_group_name  = "${azurerm_resource_group.state.name}"
        storage_account_name = "${azurerm_storage_account.state.name}"
        container_name       = "${azurerm_storage_container.state.name}"
        key                  = "management-groups.tfstate"
        use_azuread_auth     = true
      }
    }
  EOT
}
