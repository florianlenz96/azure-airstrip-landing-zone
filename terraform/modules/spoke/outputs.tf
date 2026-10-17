output "network" {
  value = {
    vnet_id              = azurerm_virtual_network.spoke.id
    subnet_ids           = { for name, subnet in azurerm_subnet.this : name => subnet.id }
    private_dns_zone_ids = var.hub.private_dns_zones
    dns_servers          = [var.hub.firewall_private_ip]
  }
}
