moved {
  from = azurerm_resource_group.this
  to   = module.spoke.azurerm_resource_group.this
}
moved {
  from = azurerm_virtual_network.spoke
  to   = module.spoke.azurerm_virtual_network.spoke
}
moved {
  from = azurerm_subnet.this
  to   = module.spoke.azurerm_subnet.this
}
moved {
  from = azurerm_network_security_group.this
  to   = module.spoke.azurerm_network_security_group.this
}
moved {
  from = azurerm_subnet_network_security_group_association.this
  to   = module.spoke.azurerm_subnet_network_security_group_association.this
}
moved {
  from = azurerm_route_table.this
  to   = module.spoke.azurerm_route_table.this
}
moved {
  from = azurerm_subnet_route_table_association.this
  to   = module.spoke.azurerm_subnet_route_table_association.this
}
moved {
  from = azurerm_virtual_network_peering.spoke_to_hub
  to   = module.spoke.azurerm_virtual_network_peering.spoke_to_hub
}
moved {
  from = azurerm_virtual_network_peering.hub_to_spoke
  to   = module.spoke.azurerm_virtual_network_peering.hub_to_spoke
}
moved {
  from = azurerm_private_dns_zone_virtual_network_link.spoke
  to   = module.spoke.azurerm_private_dns_zone_virtual_network_link.spoke
}
