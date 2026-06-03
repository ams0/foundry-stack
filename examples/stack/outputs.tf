output "resource_group_name" {
  value = azurerm_resource_group.this.name
}

output "foundry_hub_id" {
  description = "AI Foundry Hub resource ID (primary region only)"
  value       = module.foundry[var.location].hub_id
}

output "foundry_project_id" {
  description = "AI Foundry Hub Project resource ID (primary region only)"
  value       = module.foundry[var.location].project_id
}

output "foundry_portal_url" {
  description = "AI Foundry portal URL (primary region only)"
  value       = module.foundry[var.location].portal_url
}

output "ai_services_endpoints" {
  description = "Map of region → AI Services endpoint"
  value       = { for r, f in module.foundry : r => f.ai_services_endpoint }
}

output "foundry_regions" {
  description = "Regions where Foundry AI Services are deployed (primary first)"
  value       = var.foundry_regions
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

output "developer_portal_url" {
  description = "APIM developer portal URL (null when disabled)"
  value       = module.developer_portal.developer_portal_url
}

output "developer_portal_entra_redirect_uris" {
  description = "Redirect URIs to register on the Entra app for the developer portal (web platform). Add both."
  value       = module.developer_portal.entra_redirect_uris
}

output "demo_subscription_key" {
  description = "Primary key for the pre-baked 'demo-key' subscription on the ai-gateway product. Reveal with: terraform output -raw demo_subscription_key"
  value       = try(module.apim_products.subscription_keys["ai-gateway|demo-key"], null)
  sensitive   = true
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

output "estimated_monthly_cost" {
  description = "Estimated monthly infrastructure cost (USD). Does not include API/token usage."
  value = format(
    "$%.2f/month (base: $%.2f + optional: $%.2f) — excludes API/token usage",
    local.monthly_cost_total,
    local.monthly_cost_base,
    local.monthly_cost_optional,
  )
}
