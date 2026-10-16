module "management" {
  source = "./management"

  root_id                  = var.root_id
  root_management_group_id = azurerm_management_group.root.id
  logging_location         = var.logging_location
  log_retention_days       = var.log_retention_days
  defender_plans           = var.defender_plans
}
