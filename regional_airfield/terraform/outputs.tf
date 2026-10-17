output "management_group_ids" {
  value = module.foundation.management_group_ids
}

output "workload_management_group_ids" {
  value = module.foundation.workload_management_group_ids
}

output "log_analytics_workspace_id" {
  value = module.foundation.log_analytics_workspace_id
}

output "stage" {
  value = var.stage
}

output "subscriptions" {
  value = var.subscriptions
}
