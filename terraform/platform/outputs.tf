output "management_group_ids" {
  description = "IDs of the core management groups."
  value = {
    root           = azurerm_management_group.root.id
    platform       = azurerm_management_group.platform.id
    management     = azurerm_management_group.management.id
    connectivity   = azurerm_management_group.connectivity.id
    identity       = azurerm_management_group.identity.id
    landingzones   = azurerm_management_group.landingzones.id
    corp           = azurerm_management_group.corp.id
    online         = azurerm_management_group.online.id
    sandbox        = azurerm_management_group.sandbox.id
    decommissioned = azurerm_management_group.decommissioned.id
  }
}

output "log_analytics_workspace_id" {
  description = "ID of the central Log Analytics workspace."
  value       = module.management.log_analytics_workspace_id
}

output "workload_management_group_ids" {
  description = "IDs of the workload management groups, keyed by <parent>-<name>."
  value       = { for k, mg in azurerm_management_group.workload : k => mg.id }
}
