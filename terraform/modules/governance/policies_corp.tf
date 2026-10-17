locals {
  # Built-in policies that all take an "effect" parameter (Audit, Deny, Disabled)
  public_endpoint_policies = {
    key_vault     = "405c5871-3e91-4644-8a63-58e19d68ff5b" # Key Vault
    sql_database  = "1b8ca024-1d5c-4dec-8995-b1a932b41780" # Azure SQL Database
    app_service   = "1b5ef780-c53c-4a64-87f3-bb9c8c8094ba" # App Service apps
    function_apps = "969ac98b-88a8-449f-883c-2e9adb123127" # Function apps
    cosmos_db     = "797b37f7-06b8-444c-b1ad-fc62867f335a" # Cosmos DB
  }
}

resource "azurerm_policy_set_definition" "no_public_endpoints" {
  count = var.stage == "regional_airfield" ? 1 : 0

  name                = "airstrip-no-public-endpoints"
  display_name        = "No public endpoints"
  policy_type         = "Custom"
  management_group_id = var.corp_management_group_id

  # Preserve the deployed parameter schema; the assignment below always uses Deny.
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

  policy_definition_reference {
    policy_definition_id = azurerm_policy_definition.storage_private_only[0].id
    reference_id         = "storage"
  }

  # This built-in always denies NIC public-IP attachments.
  policy_definition_reference {
    policy_definition_id = "/providers/Microsoft.Authorization/policyDefinitions/83a86a26-fd1f-447c-b59d-e51f44264114"
    reference_id         = "nic_public_ip"
  }
}

resource "azurerm_management_group_policy_assignment" "no_public_endpoints" {
  count = var.stage == "regional_airfield" ? 1 : 0

  name                 = "no-public-endpoints"
  display_name         = "No public endpoints"
  management_group_id  = var.corp_management_group_id
  policy_definition_id = azurerm_policy_set_definition.no_public_endpoints[0].id

  parameters = jsonencode({
    effect = { value = "Deny" }
  })
}

# The Storage built-in also permits SecuredByPerimeter, which is not private-only.
resource "azurerm_policy_definition" "storage_private_only" {
  count               = var.stage == "regional_airfield" ? 1 : 0
  name                = "airstrip-storage-private-only"
  display_name        = "Storage accounts must disable public network access"
  policy_type         = "Custom"
  mode                = "All"
  management_group_id = var.corp_management_group_id
  policy_rule = jsonencode({
    if = {
      allOf = [
        { field = "type", equals = "Microsoft.Storage/storageAccounts" },
        { field = "Microsoft.Storage/storageAccounts/publicNetworkAccess", notEquals = "Disabled" },
      ]
    }
    then = { effect = "deny" }
  })
}

locals {
  exemptions = var.stage == "regional_airfield" ? var.exemptions : {}
}

resource "azurerm_subscription_policy_exemption" "this" {
  for_each = { for k, v in local.exemptions : k => v if length(split("/", trim(v.scope, "/"))) == 2 }

  name                            = each.key
  subscription_id                 = each.value.scope
  policy_assignment_id            = azurerm_management_group_policy_assignment.no_public_endpoints[0].id
  exemption_category              = each.value.category
  description                     = each.value.description
  expires_on                      = each.value.expires_on
  policy_definition_reference_ids = each.value.reference_ids
}

resource "azurerm_resource_group_policy_exemption" "this" {
  for_each = { for k, v in local.exemptions : k => v if length(split("/", trim(v.scope, "/"))) == 4 }

  name                            = each.key
  resource_group_id               = each.value.scope
  policy_assignment_id            = azurerm_management_group_policy_assignment.no_public_endpoints[0].id
  exemption_category              = each.value.category
  description                     = each.value.description
  expires_on                      = each.value.expires_on
  policy_definition_reference_ids = each.value.reference_ids
}

resource "azurerm_resource_policy_exemption" "this" {
  for_each = { for k, v in local.exemptions : k => v if length(split("/", trim(v.scope, "/"))) > 4 }

  name                            = each.key
  resource_id                     = each.value.scope
  policy_assignment_id            = azurerm_management_group_policy_assignment.no_public_endpoints[0].id
  exemption_category              = each.value.category
  description                     = each.value.description
  expires_on                      = each.value.expires_on
  policy_definition_reference_ids = each.value.reference_ids
}
