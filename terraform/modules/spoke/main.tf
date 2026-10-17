resource "azurerm_resource_group" "this" {
  name     = "rg-${var.root_id}-${var.name}-network"
  location = var.location
  tags     = var.tags
}

resource "azurerm_virtual_network" "spoke" {
  name                = "vnet-${var.root_id}-${var.name}"
  resource_group_name = azurerm_resource_group.this.name
  location            = azurerm_resource_group.this.location
  address_space       = var.address_space
  dns_servers         = [var.hub.firewall_private_ip]
  tags                = var.tags
}

resource "azurerm_subnet" "this" {
  for_each                          = var.subnets
  name                              = each.key
  resource_group_name               = azurerm_resource_group.this.name
  virtual_network_name              = azurerm_virtual_network.spoke.name
  address_prefixes                  = each.value.address_prefixes
  private_endpoint_network_policies = each.value.private_endpoints ? "NetworkSecurityGroupEnabled" : "Disabled"

  dynamic "delegation" {
    for_each = each.value.delegation == null ? [] : [each.value.delegation]
    content {
      name = "service"
      service_delegation {
        name    = delegation.value.name
        actions = delegation.value.actions
      }
    }
  }
}

resource "azurerm_network_security_group" "this" {
  for_each            = var.subnets
  name                = "nsg-${var.root_id}-${var.name}-${each.key}"
  resource_group_name = azurerm_resource_group.this.name
  location            = azurerm_resource_group.this.location
  tags                = var.tags

  security_rule {
    name                       = "allow-hub-dns"
    priority                   = 100
    direction                  = "Outbound"
    access                     = "Allow"
    protocol                   = "*"
    source_port_range          = "*"
    destination_port_range     = "53"
    source_address_prefix      = "*"
    destination_address_prefix = var.hub.firewall_private_ip
  }

  dynamic "security_rule" {
    for_each = each.value.rules
    content {
      name                       = security_rule.key
      priority                   = security_rule.value.priority
      direction                  = security_rule.value.direction
      access                     = security_rule.value.access
      protocol                   = security_rule.value.protocol
      source_port_range          = security_rule.value.source_port_range
      destination_port_range     = security_rule.value.destination_port_range
      source_address_prefix      = security_rule.value.source_address_prefix
      destination_address_prefix = security_rule.value.destination_address_prefix
    }
  }

  security_rule {
    name                       = "deny-unspecified-inbound"
    priority                   = 4096
    direction                  = "Inbound"
    access                     = "Deny"
    protocol                   = "*"
    source_port_range          = "*"
    destination_port_range     = "*"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }

  security_rule {
    name                       = "deny-unspecified-private-outbound"
    priority                   = 4096
    direction                  = "Outbound"
    access                     = "Deny"
    protocol                   = "*"
    source_port_range          = "*"
    destination_port_range     = "*"
    source_address_prefix      = "*"
    destination_address_prefix = "VirtualNetwork"
  }
}

resource "azurerm_subnet_network_security_group_association" "this" {
  for_each                  = azurerm_subnet.this
  subnet_id                 = each.value.id
  network_security_group_id = azurerm_network_security_group.this[each.key].id
}

resource "azurerm_route_table" "this" {
  for_each                      = var.subnets
  name                          = "rt-${var.root_id}-${var.name}-${each.key}"
  resource_group_name           = azurerm_resource_group.this.name
  location                      = azurerm_resource_group.this.location
  bgp_route_propagation_enabled = false
  tags                          = var.tags

  route {
    name                   = "internet-via-firewall"
    address_prefix         = "0.0.0.0/0"
    next_hop_type          = "VirtualAppliance"
    next_hop_in_ip_address = var.hub.firewall_private_ip
  }

  dynamic "route" {
    for_each = var.other_spoke_prefixes
    content {
      name                   = "spoke-${replace(replace(route.value, ".", "-"), "/", "-")}"
      address_prefix         = route.value
      next_hop_type          = "VirtualAppliance"
      next_hop_in_ip_address = var.hub.firewall_private_ip
    }
  }
}

resource "azurerm_subnet_route_table_association" "this" {
  for_each       = azurerm_subnet.this
  subnet_id      = each.value.id
  route_table_id = azurerm_route_table.this[each.key].id
}

resource "azurerm_virtual_network_peering" "spoke_to_hub" {
  name                         = "to-${var.hub.name}"
  resource_group_name          = azurerm_resource_group.this.name
  virtual_network_name         = azurerm_virtual_network.spoke.name
  remote_virtual_network_id    = var.hub.id
  allow_virtual_network_access = true
  allow_forwarded_traffic      = true
}

resource "azurerm_virtual_network_peering" "hub_to_spoke" {
  provider                     = azurerm.connectivity
  name                         = "to-${azurerm_virtual_network.spoke.name}"
  resource_group_name          = var.hub.resource_group_name
  virtual_network_name         = var.hub.name
  remote_virtual_network_id    = azurerm_virtual_network.spoke.id
  allow_virtual_network_access = true
  allow_forwarded_traffic      = true
}

resource "azurerm_private_dns_zone_virtual_network_link" "spoke" {
  provider              = azurerm.connectivity
  for_each              = var.hub.private_dns_zones
  name                  = "${var.root_id}-${var.subscription_id}"
  resource_group_name   = var.hub.resource_group_name
  private_dns_zone_name = each.key
  virtual_network_id    = azurerm_virtual_network.spoke.id
  registration_enabled  = false
  tags                  = var.tags
}
