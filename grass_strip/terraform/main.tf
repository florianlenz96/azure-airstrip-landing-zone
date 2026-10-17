module "foundation" {
  source = "../../terraform/modules/foundation"

  stage              = var.stage
  root_id            = var.root_id
  root_display_name  = var.root_display_name
  workloads          = var.workloads
  subscriptions      = var.subscriptions
  allowed_locations  = var.allowed_locations
  logging_location   = var.logging_location
  log_retention_days = var.log_retention_days
  defender_plans     = var.defender_plans
}

module "governance" {
  source = "../../terraform/modules/governance"

  stage                            = var.stage
  landingzones_management_group_id = module.foundation.management_group_ids.landingzones
  corp_management_group_id         = module.foundation.management_group_ids.corp
  location                         = var.logging_location
  allowed_envs                     = var.allowed_envs
  exemptions                       = var.exemptions
}
