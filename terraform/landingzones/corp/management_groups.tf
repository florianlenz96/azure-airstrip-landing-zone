data "azurerm_management_group" "corp" {
  name = "${var.root_id}-corp"
}
