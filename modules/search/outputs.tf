output "search_service_id" {
  description = "Search service resource ID"
  value       = azurerm_search_service.this.id
}

output "search_service_name" {
  description = "Search service name"
  value       = azurerm_search_service.this.name
}

output "endpoint" {
  description = "Search service endpoint URL"
  value       = "https://${azurerm_search_service.this.name}.search.windows.net"
}

output "primary_key" {
  description = "Search service primary admin key"
  value       = azurerm_search_service.this.primary_key
  sensitive   = true
}

output "principal_id" {
  description = "System-assigned managed identity principal ID"
  value       = azurerm_search_service.this.identity[0].principal_id
}
