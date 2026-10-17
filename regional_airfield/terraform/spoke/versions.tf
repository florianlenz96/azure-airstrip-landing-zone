terraform {
  required_version = ">= 1.7"
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 4.0"
    }
  }
  backend "azurerm" {}
}

provider "azurerm" {
  features {}
  subscription_id                 = var.subscription_id
  resource_provider_registrations = "none"
}

provider "azurerm" {
  alias = "connectivity"
  features {}
  subscription_id                 = var.hub.subscription_id
  resource_provider_registrations = "none"
}
