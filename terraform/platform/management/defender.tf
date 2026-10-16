# Applies to the subscription of the azurerm provider (the management subscription)
locals {
  defender_plans = {
    VirtualMachines = "servers"
    StorageAccounts = "storage"
    KeyVaults       = "key_vault"
    Arm             = "arm"
  }
}

# Foundational CSPM is free
resource "azurerm_security_center_subscription_pricing" "cspm" {
  resource_type = "CloudPosture"
  tier          = "Free"
}

resource "azurerm_security_center_subscription_pricing" "plan" {
  for_each = local.defender_plans

  resource_type = each.key
  tier          = var.defender_plans[each.value] ? "Standard" : "Free"
}
