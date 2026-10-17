output "public_access_policy_scope" {
  description = "Corp scope of the public-access restriction, or null in Grass strip."
  value       = one(azurerm_management_group_policy_assignment.no_public_endpoints[*].management_group_id)
}
