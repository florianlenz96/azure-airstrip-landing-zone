terraform {
  backend "azurerm" {
    resource_group_name  = "rg-airstrip-tfstate"
    storage_account_name = "saairstriptfstate"
    container_name       = "tfstate"
    key                  = "management-groups.tfstate"
    use_azuread_auth     = true
  }
}