resource "azurerm_resource_group" "this" {
  name     = "rg-${var.root_id}-connectivity"
  location = var.location
  tags     = var.tags
}

resource "azurerm_virtual_network" "hub" {
  name                = "vnet-${var.root_id}-hub"
  resource_group_name = azurerm_resource_group.this.name
  location            = azurerm_resource_group.this.location
  address_space       = var.address_space
  tags                = var.tags
}

resource "azurerm_subnet" "firewall" {
  name                 = "AzureFirewallSubnet"
  resource_group_name  = azurerm_resource_group.this.name
  virtual_network_name = azurerm_virtual_network.hub.name
  address_prefixes     = [var.firewall_subnet]
}

resource "azurerm_public_ip" "firewall" {
  name                = "pip-${var.root_id}-firewall"
  resource_group_name = azurerm_resource_group.this.name
  location            = azurerm_resource_group.this.location
  allocation_method   = "Static"
  sku                 = "Standard"
  tags                = var.tags
}

resource "azurerm_firewall_policy" "this" {
  name                     = "afwp-${var.root_id}"
  resource_group_name      = azurerm_resource_group.this.name
  location                 = azurerm_resource_group.this.location
  sku                      = "Standard"
  threat_intelligence_mode = "Deny"
  tags                     = var.tags

  dns {
    proxy_enabled = true
  }
}

resource "azurerm_firewall_policy_rule_collection_group" "outbound" {
  count              = length(var.network_rules) + length(var.application_rules) > 0 ? 1 : 0
  name               = "workload-outbound"
  firewall_policy_id = azurerm_firewall_policy.this.id
  priority           = 100

  dynamic "network_rule_collection" {
    for_each = length(var.network_rules) > 0 ? [1] : []
    content {
      name     = "explicit-network-access"
      priority = 100
      action   = "Allow"
      dynamic "rule" {
        for_each = var.network_rules
        content {
          name                  = rule.key
          protocols             = rule.value.protocols
          source_addresses      = rule.value.source_addresses
          destination_addresses = rule.value.destination_addresses
          destination_ports     = rule.value.destination_ports
        }
      }
    }
  }

  dynamic "application_rule_collection" {
    for_each = length(var.application_rules) > 0 ? [1] : []
    content {
      name     = "explicit-application-access"
      priority = 200
      action   = "Allow"
      dynamic "rule" {
        for_each = var.application_rules
        content {
          name              = rule.key
          source_addresses  = rule.value.source_addresses
          destination_fqdns = rule.value.destination_fqdns
          dynamic "protocols" {
            for_each = rule.value.protocols
            content {
              type = protocols.value.type
              port = protocols.value.port
            }
          }
        }
      }
    }
  }
}

resource "azurerm_firewall" "this" {
  name                = "afw-${var.root_id}"
  resource_group_name = azurerm_resource_group.this.name
  location            = azurerm_resource_group.this.location
  sku_name            = "AZFW_VNet"
  sku_tier            = "Standard"
  firewall_policy_id  = azurerm_firewall_policy.this.id
  tags                = var.tags

  ip_configuration {
    name                 = "firewall"
    subnet_id            = azurerm_subnet.firewall.id
    public_ip_address_id = azurerm_public_ip.firewall.id
  }
}

resource "azurerm_private_dns_zone" "this" {
  for_each            = var.private_dns_zones
  name                = each.key
  resource_group_name = azurerm_resource_group.this.name
  tags                = var.tags
}

resource "azurerm_private_dns_zone_virtual_network_link" "hub" {
  for_each              = azurerm_private_dns_zone.this
  name                  = "${var.root_id}-hub"
  resource_group_name   = azurerm_resource_group.this.name
  private_dns_zone_name = each.value.name
  virtual_network_id    = azurerm_virtual_network.hub.id
  registration_enabled  = false
  tags                  = var.tags
}

resource "azurerm_monitor_diagnostic_setting" "firewall" {
  name                       = "central-logging"
  target_resource_id         = azurerm_firewall.this.id
  log_analytics_workspace_id = var.log_analytics_workspace_id

  enabled_log {
    category_group = "allLogs"
  }
}
