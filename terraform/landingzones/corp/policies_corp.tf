locals {
  # Built-in policies that all take an "effect" parameter (Audit, Deny, Disabled)
  public_endpoint_policies = {
    storage       = "b2982f36-99f2-4db5-8eff-283140c09693" # Storage accounts
    key_vault     = "405c5871-3e91-4644-8a63-58e19d68ff5b" # Key Vault
    sql_database  = "1b8ca024-1d5c-4dec-8995-b1a932b41780" # Azure SQL Database
    app_service   = "1b5ef780-c53c-4a64-87f3-bb9c8c8094ba" # App Service apps
    function_apps = "969ac98b-88a8-449f-883c-2e9adb123127" # Function apps
    cosmos_db     = "797b37f7-06b8-444c-b1ad-fc62867f335a" # Cosmos DB
  }
}

resource "azurerm_policy_set_definition" "no_public_endpoints" {
  name                = "airstrip-no-public-endpoints"
  display_name        = "No public endpoints"
  policy_type         = "Custom"
  management_group_id = data.azurerm_management_group.corp.id

  parameters = jsonencode({
    effect = {
      type          = "String"
      defaultValue  = "Audit"
      allowedValues = ["Audit", "Deny", "Disabled"]
    }
  })

  dynamic "policy_definition_reference" {
    for_each = local.public_endpoint_policies

    content {
      policy_definition_id = "/providers/Microsoft.Authorization/policyDefinitions/${policy_definition_reference.value}"
      reference_id         = policy_definition_reference.key
      parameter_values     = jsonencode({ effect = { value = "[parameters('effect')]" } })
    }
  }

  # No effect parameter: NICs must not have public IPs (always audited/denied as defined by Microsoft)
  policy_definition_reference {
    policy_definition_id = "/providers/Microsoft.Authorization/policyDefinitions/83a86a26-fd1f-447c-b59d-e51f44264114"
    reference_id         = "nic_public_ip"
  }
}

resource "azurerm_management_group_policy_assignment" "no_public_endpoints" {
  name                 = "no-public-endpoints"
  display_name         = "No public endpoints"
  management_group_id  = data.azurerm_management_group.corp.id
  policy_definition_id = azurerm_policy_set_definition.no_public_endpoints.id

  parameters = jsonencode({
    effect = { value = var.public_endpoints_effect }
  })
}
