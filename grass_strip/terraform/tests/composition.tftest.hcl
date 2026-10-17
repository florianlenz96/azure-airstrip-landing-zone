mock_provider "azurerm" {}

override_module {
  target = module.foundation
  outputs = {
    management_group_ids = {
      root         = "/providers/Microsoft.Management/managementGroups/airstrip"
      landingzones = "/providers/Microsoft.Management/managementGroups/airstrip-landingzones"
      corp         = "/providers/Microsoft.Management/managementGroups/airstrip-corp"
    }
    log_analytics_workspace_id    = "/subscriptions/11111111-1111-4111-8111-111111111111/resourceGroups/rg-logging/providers/Microsoft.OperationalInsights/workspaces/log-airstrip"
    workload_management_group_ids = {}
  }
}

variables {
  allowed_locations = ["westeurope"]
}

run "governance_is_part_of_platform" {
  command = plan
  assert {
    condition     = output.stage == "grass_strip" && module.governance.public_access_policy_scope == null
    error_message = "Grass strip must not assign the public-access restriction."
  }
}

run "reject_wrong_stage" {
  command = plan
  variables {
    stage = "regional_airfield"
  }
  expect_failures = [var.stage]
}
