moved {
  from = azurerm_resource_group.this
  to   = module.connectivity.azurerm_resource_group.this
}
moved {
  from = azurerm_virtual_network.hub
  to   = module.connectivity.azurerm_virtual_network.hub
}
moved {
  from = azurerm_subnet.firewall
  to   = module.connectivity.azurerm_subnet.firewall
}
moved {
  from = azurerm_public_ip.firewall
  to   = module.connectivity.azurerm_public_ip.firewall
}
moved {
  from = azurerm_firewall_policy.this
  to   = module.connectivity.azurerm_firewall_policy.this
}
moved {
  from = azurerm_firewall_policy_rule_collection_group.outbound
  to   = module.connectivity.azurerm_firewall_policy_rule_collection_group.outbound
}
moved {
  from = azurerm_firewall.this
  to   = module.connectivity.azurerm_firewall.this
}
moved {
  from = azurerm_private_dns_zone.this
  to   = module.connectivity.azurerm_private_dns_zone.this
}
moved {
  from = azurerm_private_dns_zone_virtual_network_link.hub
  to   = module.connectivity.azurerm_private_dns_zone_virtual_network_link.hub
}
moved {
  from = azurerm_monitor_diagnostic_setting.firewall
  to   = module.connectivity.azurerm_monitor_diagnostic_setting.firewall
}
