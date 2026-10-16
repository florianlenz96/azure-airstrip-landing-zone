resource "azurerm_resource_group" "logging" {
  name     = "rg-${var.root_id}-logging"
  location = var.logging_location
}

resource "azurerm_log_analytics_workspace" "this" {
  name                = "log-${var.root_id}"
  location            = azurerm_resource_group.logging.location
  resource_group_name = azurerm_resource_group.logging.name
  sku                 = "PerGB2018"
  retention_in_days   = var.log_retention_days
}
