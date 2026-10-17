mock_provider "azurerm" {
  mock_resource "azurerm_firewall_policy" {
    defaults = {
      id = "/subscriptions/22222222-2222-4222-8222-222222222222/resourceGroups/rg-airstrip-connectivity/providers/Microsoft.Network/firewallPolicies/afwp-airstrip"
    }
  }
}

variables {
  stage                      = "regional_airfield"
  root_id                    = "airstrip"
  subscription_id            = "22222222-2222-4222-8222-222222222222"
  location                   = "westeurope"
  tags                       = { owner = "platform", cost-center = "platform", env = "prod" }
  address_space              = ["10.0.0.0/16"]
  firewall_subnet            = "10.0.0.0/26"
  private_dns_zones          = ["privatelink.blob.core.windows.net"]
  log_analytics_workspace_id = "/subscriptions/11111111-1111-4111-8111-111111111111/resourceGroups/rg-airstrip-logging/providers/Microsoft.OperationalInsights/workspaces/log-airstrip"
}

run "native_spoke_input_export" {
  command = plan
  assert {
    condition     = output.spoke_inputs.hub.subscription_id == var.subscription_id && output.spoke_inputs.hub.name == "vnet-${var.root_id}-hub"
    error_message = "The native export must pass the deployed hub subscription and VNet to spoke inputs."
  }
}
