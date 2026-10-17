mock_provider "azurerm" {
  mock_resource "azurerm_management_group_policy_assignment" {
    defaults = {
      id = "/providers/Microsoft.Management/managementGroups/airstrip-corp/providers/Microsoft.Authorization/policyAssignments/no-public-endpoints"
      identity = {
        type         = "SystemAssigned"
        principal_id = "11111111-1111-4111-8111-111111111111"
        tenant_id    = "11111111-1111-4111-8111-111111111111"
      }
    }
  }
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

variables {
  landingzones_management_group_id = "/providers/Microsoft.Management/managementGroups/airstrip-landingzones"
  corp_management_group_id         = "/providers/Microsoft.Management/managementGroups/airstrip-corp"
}

run "grass_strip" {
  command = plan
  assert {
    condition     = length(azurerm_management_group_policy_assignment.no_public_endpoints) == 0 && length(azurerm_policy_definition.storage_private_only) == 0
    error_message = "Grass strip must not assign public-access restrictions."
  }
}

run "regional_airfield" {
  command = plan
  variables {
    stage = "regional_airfield"
  }
  assert {
    condition     = jsondecode(azurerm_management_group_policy_assignment.no_public_endpoints[0].parameters).effect.value == "Deny"
    error_message = "Regional airfield must enforce Deny."
  }
  assert {
    condition     = azurerm_management_group_policy_assignment.no_public_endpoints[0].management_group_id == "/providers/Microsoft.Management/managementGroups/airstrip-corp"
    error_message = "The initiative must remain scoped to Corp, not Online."
  }
  assert {
    condition     = jsondecode(azurerm_policy_definition.storage_private_only[0].policy_rule).if.allOf[1].notEquals == "Disabled"
    error_message = "Storage public access must be disabled, including SecuredByPerimeter."
  }
}

run "explicit_exemption" {
  command = apply
  variables {
    stage = "regional_airfield"
    exemptions = {
      migration = {
        scope         = "/subscriptions/33333333-3333-4333-8333-333333333333"
        description   = "Migrate legacy application using restricted service firewall rules"
        expires_on    = "2099-01-01T00:00:00Z"
        reference_ids = ["storage"]
      }
    }
  }
  assert {
    condition     = azurerm_subscription_policy_exemption.this["migration"].policy_definition_reference_ids == tolist(["storage"])
    error_message = "Exceptions must target their explicit policy references."
  }
}

run "reject_expired_exemption" {
  command = plan
  variables {
    stage = "regional_airfield"
    exemptions = {
      migration = {
        scope       = "/subscriptions/33333333-3333-4333-8333-333333333333"
        description = "Expired migration window"
        expires_on  = "2000-01-01T00:00:00Z"
      }
    }
  }
  expect_failures = [azurerm_management_group_policy_assignment.require_env]
}

run "reject_invalid_exemption_scope" {
  command = plan
  variables {
    stage = "regional_airfield"
    exemptions = {
      migration = {
        scope       = "/invalid/scope"
        description = "Invalid migration scope"
        expires_on  = "2099-01-01T00:00:00Z"
      }
    }
  }
  expect_failures = [var.exemptions]
}
