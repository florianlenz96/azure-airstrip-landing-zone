data "azurerm_management_group" "landingzones" {
  name = "${var.root_id}-landingzones"
}
