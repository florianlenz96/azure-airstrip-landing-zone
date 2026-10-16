terraform {
  required_version = ">= 1.5"

  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 4.0"
    }
  }

  backend "azurerm" {
    resource_group_name  = "rg-airstrip-tfstate"
    storage_account_name = "saairstriptfstate"
    container_name       = "tfstate"
    key                  = "landingzones-corp.tfstate"
    use_azuread_auth     = true
  }
}

provider "azurerm" {
  features {}
  resource_provider_registrations = "none"
}
