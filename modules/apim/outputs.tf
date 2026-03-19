output "gateway_url" {
  description = "APIM gateway URL"
  value       = var.enable_apim ? azurerm_api_management.this[0].gateway_url : null
}

output "api_id" {
  description = "Foundry API resource ID"
  value       = var.enable_apim ? azurerm_api_management_api.foundry[0].id : null
}

output "principal_id" {
  description = "APIM system-assigned identity principal ID"
  value       = var.enable_apim ? azurerm_api_management.this[0].identity[0].principal_id : null
}
