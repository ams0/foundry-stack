output "resource_group_name" {
  value = azurerm_resource_group.this.name
}

output "foundry_hub_id" {
  value = module.foundry.hub_id
}

output "foundry_project_id" {
  value = module.foundry.project_id
}

output "foundry_portal_url" {
  value = module.foundry.portal_url
}

output "ai_services_endpoint" {
  value = module.foundry.ai_services_endpoint
}

output "storage_account_name" {
  value = module.storage.storage_account_name
}

output "search_endpoint" {
  value = module.search.endpoint
}

output "key_vault_uri" {
  value = module.keyvault.key_vault_uri
}

output "estimated_monthly_cost" {
  description = "Estimated monthly infrastructure cost (USD). Does not include API/token usage."
  value       = format("$%.2f/month — excludes API/token usage", local.estimated_monthly_cost)
}
