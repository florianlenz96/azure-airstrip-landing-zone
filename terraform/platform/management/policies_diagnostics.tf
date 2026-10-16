locals {
  # Built-in: Enable allLogs category group resource logging for supported resources to Log Analytics
  all_logs_initiative_id = "/providers/Microsoft.Authorization/policySetDefinitions/0884adba-2312-4468-abeb-5422caed1038"
  # Built-in: Configure Azure Activity logs to stream to specified Log Analytics workspace
  activity_log_policy_id = "/providers/Microsoft.Authorization/policyDefinitions/2465583e-4e78-4c15-b6be-a36cbc7c8b0f"

  diagnostics_assignments = {
    all-logs     = local.all_logs_initiative_id
    activity-log = local.activity_log_policy_id
  }
  diagnostics_roles = ["Monitoring Contributor", "Log Analytics Contributor"]

  diagnostics_role_assignments = {
    for pair in setproduct(keys(local.diagnostics_assignments), local.diagnostics_roles) :
    "${pair[0]}/${pair[1]}" => { assignment = pair[0], role = pair[1] }
  }
}

resource "azurerm_management_group_policy_assignment" "diagnostics" {
  for_each = local.diagnostics_assignments

  name                 = "diag-${each.key}"
  display_name         = "Send diagnostics to Log Analytics (${each.key})"
  management_group_id  = var.root_management_group_id
  policy_definition_id = each.value
  location             = var.logging_location

  identity {
    type = "SystemAssigned"
  }

  parameters = jsonencode({
    logAnalytics = { value = azurerm_log_analytics_workspace.this.id }
  })
}

resource "azurerm_role_assignment" "diagnostics" {
  for_each = local.diagnostics_role_assignments

  scope                            = var.root_management_group_id
  role_definition_name             = each.value.role
  principal_id                     = azurerm_management_group_policy_assignment.diagnostics[each.value.assignment].identity[0].principal_id
  skip_service_principal_aad_check = true
}
