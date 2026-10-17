module "connectivity" {
  source = "../../../terraform/modules/connectivity"

  stage                      = var.stage
  root_id                    = var.root_id
  subscription_id            = var.subscription_id
  location                   = var.location
  tags                       = var.tags
  address_space              = var.address_space
  firewall_subnet            = var.firewall_subnet
  private_dns_zones          = var.private_dns_zones
  log_analytics_workspace_id = var.log_analytics_workspace_id
  network_rules              = var.network_rules
  application_rules          = var.application_rules
}

output "hub" {
  value = module.connectivity.hub
}

output "spoke_inputs" {
  description = "Export with terraform output -json spoke_inputs to a spoke var file."
  value       = { hub = module.connectivity.hub }
}
