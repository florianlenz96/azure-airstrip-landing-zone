locals {
  workload_mgs = merge(
    { for k, v in var.workloads.corp : "corp-${k}" => { parent = "corp", name = k, display_name = v } },
    { for k, v in var.workloads.online : "online-${k}" => { parent = "online", name = k, display_name = v } },
  )
}

resource "azurerm_management_group" "root" {
  name         = var.root_id
  display_name = var.root_display_name
}

resource "azurerm_management_group" "platform" {
  name                       = "${var.root_id}-platform"
  display_name               = "Platform"
  parent_management_group_id = azurerm_management_group.root.id
}

resource "azurerm_management_group" "management" {
  name                       = "${var.root_id}-management"
  display_name               = "Management"
  parent_management_group_id = azurerm_management_group.platform.id
}

resource "azurerm_management_group" "connectivity" {
  name                       = "${var.root_id}-connectivity"
  display_name               = "Connectivity"
  parent_management_group_id = azurerm_management_group.platform.id
}

resource "azurerm_management_group" "identity" {
  name                       = "${var.root_id}-identity"
  display_name               = "Identity"
  parent_management_group_id = azurerm_management_group.platform.id
}

resource "azurerm_management_group" "landingzones" {
  name                       = "${var.root_id}-landingzones"
  display_name               = "Landing Zones"
  parent_management_group_id = azurerm_management_group.root.id
}

resource "azurerm_management_group" "corp" {
  name                       = "${var.root_id}-corp"
  display_name               = "Corp"
  parent_management_group_id = azurerm_management_group.landingzones.id
}

resource "azurerm_management_group" "online" {
  name                       = "${var.root_id}-online"
  display_name               = "Online"
  parent_management_group_id = azurerm_management_group.landingzones.id
}

resource "azurerm_management_group" "sandbox" {
  name                       = "${var.root_id}-sandbox"
  display_name               = "Sandbox"
  parent_management_group_id = azurerm_management_group.root.id
}

resource "azurerm_management_group" "decommissioned" {
  name                       = "${var.root_id}-decommissioned"
  display_name               = "Decommissioned"
  parent_management_group_id = azurerm_management_group.root.id
}

resource "azurerm_management_group" "workload" {
  for_each = local.workload_mgs

  name         = "${var.root_id}-${each.value.parent}-${each.value.name}"
  display_name = each.value.display_name
  parent_management_group_id = (
    each.value.parent == "corp" ? azurerm_management_group.corp.id : azurerm_management_group.online.id
  )
}

locals {
  management_group_ids = merge(
    {
      management     = azurerm_management_group.management.id
      connectivity   = azurerm_management_group.connectivity.id
      identity       = azurerm_management_group.identity.id
      corp           = azurerm_management_group.corp.id
      online         = azurerm_management_group.online.id
      sandbox        = azurerm_management_group.sandbox.id
      decommissioned = azurerm_management_group.decommissioned.id
    },
    { for k, mg in azurerm_management_group.workload : k => mg.id },
  )

  subscription_associations = {
    for pair in flatten([
      for mg, ids in var.subscriptions : [for id in ids : { mg = mg, id = id }]
    ]) : "${pair.mg}/${pair.id}" => pair
  }
}

resource "azurerm_management_group_subscription_association" "this" {
  for_each = local.subscription_associations

  management_group_id = local.management_group_ids[each.value.mg]
  subscription_id     = "/subscriptions/${each.value.id}"
}
