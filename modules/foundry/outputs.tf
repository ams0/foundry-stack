output "hub_id" {
  description = "AI Foundry Hub resource ID (null when create_hub = false)"
  value       = var.create_hub ? azurerm_ai_foundry.this[0].id : null
}

output "hub_principal_id" {
  description = "AI Foundry Hub system-assigned identity principal ID (null when create_hub = false)"
  value       = var.create_hub ? azurerm_ai_foundry.this[0].identity[0].principal_id : null
}

output "project_id" {
  description = "AI Foundry Project resource ID (legacy portal). Null when create_hub = false."
  value       = var.create_hub ? azurerm_ai_foundry_project.this[0].id : null
}

output "ai_services_id" {
  description = "AI Services resource ID"
  value       = azapi_resource.ai_services.id
}

output "ai_services_endpoint" {
  description = "AI Services endpoint"
  value       = azapi_resource.ai_services.output.properties.endpoint
}

output "ai_services_principal_id" {
  description = "AI Services system-assigned identity principal ID"
  value       = azapi_resource.ai_services.output.identity.principalId
}

output "ai_services_primary_key" {
  description = "AI Services primary API key"
  value       = data.azapi_resource_action.ai_services_keys.output.key1
  sensitive   = true
}

output "foundry_project_id" {
  description = "Cognitive Account Project resource ID (new Foundry portal)"
  value       = azurerm_cognitive_account_project.this.id
}

output "foundry_project_endpoints" {
  description = "Cognitive Account Project endpoints"
  value       = azurerm_cognitive_account_project.this.endpoints
}

output "portal_url" {
  description = "Azure AI Foundry portal URL for the project (legacy portal; null when create_hub = false)"
  value       = var.create_hub ? "https://ai.azure.com/project/${azurerm_ai_foundry_project.this[0].name}/overview?wsid=${azurerm_ai_foundry_project.this[0].id}" : null
}

output "deployment_ids" {
  description = "Map of deployment name to deployment ID"
  value       = { for k, v in azurerm_cognitive_deployment.this : k => v.id }
}
