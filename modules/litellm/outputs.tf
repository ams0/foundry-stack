output "endpoint_url" {
  description = "LiteLLM endpoint URL"
  value       = var.enable_litellm ? azurerm_container_app.this[0].ingress[0].fqdn : null
}

output "environment_id" {
  description = "Container App Environment ID"
  value       = var.enable_litellm ? azurerm_container_app_environment.this[0].id : null
}

output "principal_id" {
  description = "LiteLLM Container App system-assigned identity principal ID"
  value       = var.enable_litellm ? try(azurerm_container_app.this[0].identity[0].principal_id, null) : null
}

output "master_key" {
  description = "LiteLLM master API key for proxy authentication"
  value       = var.enable_litellm ? local.litellm_master_key : null
  sensitive   = true
}
