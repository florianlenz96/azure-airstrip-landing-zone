output "hub" {
  value = {
    id                         = azurerm_virtual_network.hub.id
    name                       = azurerm_virtual_network.hub.name
    resource_group_name        = azurerm_resource_group.this.name
    subscription_id            = var.subscription_id
    location                   = var.location
    address_space              = var.address_space
    firewall_private_ip        = azurerm_firewall.this.ip_configuration[0].private_ip_address
    private_dns_zones          = { for name, zone in azurerm_private_dns_zone.this : name => zone.id }
    log_analytics_workspace_id = var.log_analytics_workspace_id
  }
}
