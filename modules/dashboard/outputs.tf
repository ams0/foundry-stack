output "dashboard_id" {
  description = "Azure Portal Dashboard resource ID"
  value       = azurerm_portal_dashboard.this.id
}

output "dashboard_url" {
  description = "Direct URL to open the dashboard in Azure Portal"
  value       = "https://portal.azure.com/#@/dashboard/arm${azurerm_portal_dashboard.this.id}"
}
