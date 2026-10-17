locals {
  required_tags = ["owner", "cost-center", "env"]
  # Built-in policies: Require a tag on resource groups, Inherit a tag from the resource group if missing
  require_tag_policy_id = "/providers/Microsoft.Authorization/policyDefinitions/96670d01-0a4d-4649-9c89-2d3abc0a5025"
  inherit_tag_policy_id = "/providers/Microsoft.Authorization/policyDefinitions/ea3f2387-9b95-492a-a190-fcdc54f7b070"
}

# owner and cost-center only have to exist, env must also have an allowed value
resource "azurerm_management_group_policy_assignment" "require_tag" {
  for_each = toset(["owner", "cost-center"])

  name                 = "require-${each.key}"
  display_name         = "Require tag ${each.key} on resource groups"
  management_group_id  = var.landingzones_management_group_id
  policy_definition_id = local.require_tag_policy_id

  parameters = jsonencode({
    tagName = { value = each.key }
  })
}

resource "azurerm_policy_definition" "env_tag_values" {
  name                = "airstrip-env-tag-values"
  display_name        = "Require tag env with an allowed value on resource groups"
  policy_type         = "Custom"
  mode                = "All"
  management_group_id = var.landingzones_management_group_id

  parameters = jsonencode({
    allowedValues = { type = "Array" }
  })

  policy_rule = jsonencode({
    if = {
      allOf = [
        { field = "type", equals = "Microsoft.Resources/subscriptions/resourceGroups" },
        { not = { field = "tags['env']", in = "[parameters('allowedValues')]" } },
      ]
    }
    then = { effect = "deny" }
  })
}

resource "azurerm_management_group_policy_assignment" "require_env" {
  name                 = "require-env"
  display_name         = "Require tag env on resource groups"
  management_group_id  = var.landingzones_management_group_id
  policy_definition_id = azurerm_policy_definition.env_tag_values.id

  parameters = jsonencode({
    allowedValues = { value = var.allowed_envs }
  })

  lifecycle {
    precondition {
      condition     = var.stage == "regional_airfield" || length(var.exemptions) == 0
      error_message = "Grass strip cannot configure public-access policy exemptions."
    }
    precondition {
      condition = alltrue([
        for e in values(var.exemptions) : timecmp(e.expires_on, plantimestamp()) > 0 &&
        length(setsubtract(toset(e.reference_ids), toset(["storage", "key_vault", "sql_database", "app_service", "function_apps", "cosmos_db", "nic_public_ip"]))) == 0
      ])
      error_message = "Exemptions must be unexpired and reference known policies."
    }
  }
}

# Resources inherit the tags from their resource group (Modify needs an identity)
resource "azurerm_management_group_policy_assignment" "inherit_tag" {
  for_each = toset(local.required_tags)

  name                 = "inherit-${each.key}"
  display_name         = "Inherit tag ${each.key} from resource group"
  management_group_id  = var.landingzones_management_group_id
  policy_definition_id = local.inherit_tag_policy_id
  location             = var.location

  identity {
    type = "SystemAssigned"
  }

  parameters = jsonencode({
    tagName = { value = each.key }
  })
}

resource "azurerm_role_assignment" "inherit_tag" {
  for_each = azurerm_management_group_policy_assignment.inherit_tag

  scope                            = var.landingzones_management_group_id
  role_definition_name             = "Contributor"
  principal_id                     = each.value.identity[0].principal_id
  skip_service_principal_aad_check = true
}
