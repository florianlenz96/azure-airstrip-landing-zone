module "spoke" {
  source = "../../../terraform/modules/spoke"
  providers = {
    azurerm              = azurerm
    azurerm.connectivity = azurerm.connectivity
  }

  stage                = var.stage
  root_id              = var.root_id
  subscription_id      = var.subscription_id
  name                 = var.name
  location             = var.location
  tags                 = var.tags
  address_space        = var.address_space
  other_spoke_prefixes = var.other_spoke_prefixes
  hub                  = var.hub
  subnets              = var.subnets
}

output "network" {
  value = module.spoke.network
}
