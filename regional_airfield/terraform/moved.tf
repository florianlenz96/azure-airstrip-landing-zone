moved {
  from = azurerm_management_group.root
  to   = module.foundation.azurerm_management_group.root
}
moved {
  from = azurerm_management_group.platform
  to   = module.foundation.azurerm_management_group.platform
}
moved {
  from = azurerm_management_group.management
  to   = module.foundation.azurerm_management_group.management
}
moved {
  from = azurerm_management_group.connectivity
  to   = module.foundation.azurerm_management_group.connectivity
}
moved {
  from = azurerm_management_group.identity
  to   = module.foundation.azurerm_management_group.identity
}
moved {
  from = azurerm_management_group.landingzones
  to   = module.foundation.azurerm_management_group.landingzones
}
moved {
  from = azurerm_management_group.corp
  to   = module.foundation.azurerm_management_group.corp
}
moved {
  from = azurerm_management_group.online
  to   = module.foundation.azurerm_management_group.online
}
moved {
  from = azurerm_management_group.sandbox
  to   = module.foundation.azurerm_management_group.sandbox
}
moved {
  from = azurerm_management_group.decommissioned
  to   = module.foundation.azurerm_management_group.decommissioned
}
moved {
  from = azurerm_management_group.workload
  to   = module.foundation.azurerm_management_group.workload
}
moved {
  from = azurerm_management_group_subscription_association.this
  to   = module.foundation.azurerm_management_group_subscription_association.this
}
moved {
  from = azurerm_management_group_policy_assignment.allowed_locations
  to   = module.foundation.azurerm_management_group_policy_assignment.allowed_locations
}
moved {
  from = azurerm_management_group_policy_assignment.allowed_rg_locations
  to   = module.foundation.azurerm_management_group_policy_assignment.allowed_rg_locations
}
moved {
  from = module.management
  to   = module.foundation.module.management
}
