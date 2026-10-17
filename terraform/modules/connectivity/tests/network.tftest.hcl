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

run "default_deny_and_dns" {
  command = plan
  assert {
    condition     = length(azurerm_firewall_policy_rule_collection_group.outbound) == 0
    error_message = "No outbound allow rule may be created implicitly."
  }
  assert {
    condition     = one(azurerm_firewall_policy.this.dns).proxy_enabled && !azurerm_private_dns_zone_virtual_network_link.hub["privatelink.blob.core.windows.net"].registration_enabled
    error_message = "The hub must resolve shared private DNS through Firewall DNS proxy."
  }
}

run "explicit_outbound_rule" {
  command = plan
  variables {
    application_rules = {
      packages = {
        source_addresses  = ["10.1.1.0/24"]
        destination_fqdns = ["packages.microsoft.com"]
        protocols         = [{ type = "Https", port = 443 }]
      }

    }
  }
  assert {
    condition     = one(azurerm_firewall_policy_rule_collection_group.outbound[0].application_rule_collection).action == "Allow"
    error_message = "Configured outbound destinations must create explicit allow rules."
  }
}

run "reject_broad_outbound_access" {
  command = plan
  variables {
    network_rules = {
      internet = {
        source_addresses      = ["10.1.0.0/16"]
        destination_addresses = ["0.0.0.0/0"]
        destination_ports     = ["*"]
        protocols             = ["TCP"]
      }
    }
  }
  expect_failures = [var.network_rules]
}

run "reject_undersized_firewall_subnet" {
  command = plan
  variables {
    firewall_subnet = "10.0.0.0/27"
  }
  expect_failures = [var.firewall_subnet]
}
