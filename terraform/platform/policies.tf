locals {
  # Built-in: Allowed locations, Allowed locations for resource groups
  allowed_locations_policy_id    = "/providers/Microsoft.Authorization/policyDefinitions/e56962a6-4747-49cd-b67b-bf8b01975c4c"
  allowed_rg_locations_policy_id = "/providers/Microsoft.Authorization/policyDefinitions/e765b5de-1225-4ba3-bd56-1ac6695af988"
}

resource "azurerm_management_group_policy_assignment" "allowed_locations" {
  name                 = "allowed-locations"
  display_name         = "Allowed locations"
  management_group_id  = azurerm_management_group.root.id
  policy_definition_id = local.allowed_locations_policy_id

  parameters = jsonencode({
    listOfAllowedLocations = { value = var.allowed_locations }
  })
}

resource "azurerm_management_group_policy_assignment" "allowed_rg_locations" {
  name                 = "allowed-rg-locations"
  display_name         = "Allowed locations for resource groups"
  management_group_id  = azurerm_management_group.root.id
  policy_definition_id = local.allowed_rg_locations_policy_id

  parameters = jsonencode({
    listOfAllowedLocations = { value = var.allowed_locations }
  })
}
