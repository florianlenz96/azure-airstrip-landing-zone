mock_provider "azurerm" {}
mock_provider "azurerm" {
  alias = "connectivity"
}

variables {
  stage                = "regional_airfield"
  root_id              = "airstrip"
  subscription_id      = "33333333-3333-4333-8333-333333333333"
  name                 = "erp"
  location             = "westeurope"
  tags                 = { owner = "erp", cost-center = "erp", env = "prod" }
  address_space        = ["10.1.0.0/16"]
  other_spoke_prefixes = ["10.2.0.0/16"]
  hub = {
    id                         = "/subscriptions/22222222-2222-4222-8222-222222222222/resourceGroups/rg-airstrip-connectivity/providers/Microsoft.Network/virtualNetworks/vnet-airstrip-hub"
    name                       = "vnet-airstrip-hub"
    resource_group_name        = "rg-airstrip-connectivity"
    subscription_id            = "22222222-2222-4222-8222-222222222222"
    firewall_private_ip        = "10.0.0.4"
    private_dns_zones          = { "privatelink.blob.core.windows.net" = "/subscriptions/22222222-2222-4222-8222-222222222222/resourceGroups/rg-airstrip-connectivity/providers/Microsoft.Network/privateDnsZones/privatelink.blob.core.windows.net" }
    log_analytics_workspace_id = "/subscriptions/11111111-1111-4111-8111-111111111111/resourceGroups/rg-airstrip-logging/providers/Microsoft.OperationalInsights/workspaces/log-airstrip"
  }
  subnets = {
    apps              = { address_prefixes = ["10.1.1.0/24"] }
    private-endpoints = { address_prefixes = ["10.1.2.0/24"], private_endpoints = true }
  }
}

run "spoke_controls" {
  command = plan
  assert {
    condition     = length(azurerm_subnet_network_security_group_association.this) == 2 && length(azurerm_subnet_route_table_association.this) == 2
    error_message = "Every subnet must have NSG and route-table associations."
  }

  assert {
    condition     = alltrue([for table in azurerm_route_table.this : alltrue([for route in table.route : route.next_hop_type == "VirtualAppliance" && route.next_hop_in_ip_address == "10.0.0.4"])])
    error_message = "Default and inter-spoke routes must use Firewall."
  }
  assert {
    condition     = alltrue([for table in azurerm_route_table.this : toset([for route in table.route : route.address_prefix]) == toset(["0.0.0.0/0", "10.2.0.0/16"])])
    error_message = "Routes must cover Internet and configured remote spokes."
  }
  assert {
    condition     = azurerm_virtual_network_peering.spoke_to_hub.allow_forwarded_traffic && azurerm_virtual_network_peering.hub_to_spoke.allow_forwarded_traffic
    error_message = "Both peering directions must permit forwarded traffic."
  }
  assert {
    condition     = azurerm_subnet.this["private-endpoints"].private_endpoint_network_policies == "NetworkSecurityGroupEnabled"
    error_message = "Private-endpoint traffic must be controlled by NSGs."
  }
  assert {
    condition     = alltrue([for nsg in azurerm_network_security_group.this : length([for rule in nsg.security_rule : rule if rule.direction == "Inbound" && rule.access == "Deny" && rule.priority == 4096]) == 1])
    error_message = "Default VNet inbound access must not bypass explicit NSG rules."
  }
}

run "reject_nsg_priority_collision" {
  command = plan
  variables {
    subnets = {
      apps = {
        address_prefixes = ["10.1.1.0/24"]
        rules = {
          bypass = {
            priority                   = 100
            direction                  = "Inbound"
            access                     = "Allow"
            protocol                   = "*"
            destination_port_range     = "*"
            source_address_prefix      = "*"
            destination_address_prefix = "*"
          }
        }
      }
    }
  }
  expect_failures = [var.subnets]
}

run "reject_delegated_private_endpoint_subnet" {
  command = plan
  variables {
    subnets = {
      private-endpoints = {
        address_prefixes  = ["10.1.2.0/24"]
        private_endpoints = true
        delegation = {
          name    = "Microsoft.Web/serverFarms"
          actions = ["Microsoft.Network/virtualNetworks/subnets/action"]
        }
      }
    }
  }
  expect_failures = [var.subnets]
}
