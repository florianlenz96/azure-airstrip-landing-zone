mock_provider "azurerm" {
  mock_resource "azurerm_policy_definition" {
    defaults = {
      id = "/providers/Microsoft.Management/managementGroups/airstrip-corp/providers/Microsoft.Authorization/policyDefinitions/airstrip-storage-private-only"
    }
  }
  mock_resource "azurerm_policy_set_definition" {
    defaults = {
      id = "/providers/Microsoft.Management/managementGroups/airstrip-corp/providers/Microsoft.Authorization/policySetDefinitions/airstrip-no-public-endpoints"
    }
  }
}

override_module {
  target = module.foundation
  outputs = {
    management_group_ids = {
      root         = "/providers/Microsoft.Management/managementGroups/airstrip"
      landingzones = "/providers/Microsoft.Management/managementGroups/airstrip-landingzones"
      corp         = "/providers/Microsoft.Management/managementGroups/airstrip-corp"
      connectivity = "/providers/Microsoft.Management/managementGroups/airstrip-connectivity"
    }
    log_analytics_workspace_id    = "/subscriptions/11111111-1111-4111-8111-111111111111/resourceGroups/rg-logging/providers/Microsoft.OperationalInsights/workspaces/log-airstrip"
    workload_management_group_ids = {}
  }
}

variables {
  allowed_locations = ["westeurope"]
}

run "shared_foundation_and_regional_governance" {
  command = plan
  assert {
    condition     = output.stage == "regional_airfield" && contains(keys(output.management_group_ids), "connectivity")
    error_message = "This entry point must retain the foundation and enable Regional airfield."
  }
  assert {
    condition     = module.governance.public_access_policy_scope == "/providers/Microsoft.Management/managementGroups/airstrip-corp"
    error_message = "Regional governance must restrict Corp, not Online."
  }
}

run "reject_wrong_stage" {
  command = plan
  variables {
    stage = "grass_strip"
  }
  expect_failures = [var.stage]
}
