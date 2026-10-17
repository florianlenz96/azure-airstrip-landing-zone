output "log_analytics_workspace_id" {
  description = "ID of the central Log Analytics workspace."
  value       = azurerm_log_analytics_workspace.this.id
}
