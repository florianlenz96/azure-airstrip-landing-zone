terraform {
  required_version = ">= 1.5"

  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 4.0"
    }
  }
}

# The subscription comes from ARM_SUBSCRIPTION_ID and must be the management subscription
provider "azurerm" {
  features {}
  resource_provider_registrations = "none"
}
