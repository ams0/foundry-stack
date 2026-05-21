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

output "apim_gateway_url" {
  value = module.apim.gateway_url
}

output "litellm_endpoint" {
  value = module.litellm.endpoint_url
}

output "cosmosdb_endpoint" {
  value = module.cosmosdb.endpoint
}

output "openclaw_url" {
  value = module.openclaw.endpoint_url
}

output "openclaw_gateway_token" {
  description = "OpenClaw gateway auth token. Retrieve with: terraform output -raw openclaw_gateway_token"
  value       = module.openclaw.gateway_token
  sensitive   = true
}

output "dashboard_url" {
  description = "Azure Portal Dashboard URL"
  value       = module.dashboard.dashboard_url
}

output "event_hub_namespace_endpoint" {
  description = "Event Hubs namespace endpoint (consumed by APIM EH loggers)."
  value       = module.event_hub.namespace_endpoint
}

output "logic_app_name" {
  description = "Usage-ingestion Logic App name (empty when disabled)."
  value       = module.logic_app.name
}

output "estimated_monthly_cost" {
  description = "Estimated monthly infrastructure cost (USD). Does not include API/token usage."
  value = format(
    "$%.2f/month (base: $%.2f + optional: $%.2f) — excludes API/token usage",
    local.monthly_cost_total,
    local.monthly_cost_base,
    local.monthly_cost_optional,
  )
}
