mock_provider "azurerm" {
  mock_resource "azurerm_log_analytics_workspace" {
    defaults = {
      id = "/subscriptions/11111111-1111-4111-8111-111111111111/resourceGroups/rg-airstrip-logging/providers/Microsoft.OperationalInsights/workspaces/log-airstrip"
    }
  }
  mock_resource "azurerm_management_group" {
    defaults = {
      id = "/providers/Microsoft.Management/managementGroups/airstrip"
    }
  }
}

variables {
  allowed_locations = ["westeurope"]
}

run "grass_strip" {
  command = plan
  assert {
    condition     = length(azurerm_management_group.connectivity) == 0 && !contains(keys(output.management_group_ids), "connectivity")
    error_message = "Grass strip must not create Connectivity."
  }
  assert {
    condition     = azurerm_management_group.management.name == "airstrip-management" && azurerm_management_group.corp.name == "airstrip-corp"
    error_message = "The remaining hierarchy must be preserved."
  }
}

run "regional_airfield" {
  command = plan
  variables {
    stage = "regional_airfield"
  }
  assert {
    condition     = length(azurerm_management_group.connectivity) == 1 && contains(keys(output.management_group_ids), "connectivity")
    error_message = "Regional airfield must create Connectivity."
  }
}

run "invalid_stage" {
  command = plan
  variables {
    stage = "unknown"
  }
  expect_failures = [var.stage]
}
