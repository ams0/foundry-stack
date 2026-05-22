output "resource_group_name" {
  value = azurerm_resource_group.this.name
}

output "foundry_portal_url" {
  value = module.foundry.portal_url
}

output "ai_services_endpoint" {
  value = module.foundry.ai_services_endpoint
}

output "litellm_endpoint" {
  description = "LiteLLM proxy endpoint (consumed by OpenClaw)."
  value       = module.litellm.endpoint_url
}

output "openclaw_url" {
  description = "OpenClaw container app URL."
  value       = module.openclaw.endpoint_url
}

output "openclaw_gateway_token" {
  description = "OpenClaw gateway auth token. Retrieve with: terraform output -raw openclaw_gateway_token"
  value       = module.openclaw.gateway_token
  sensitive   = true
}

output "estimated_monthly_cost" {
  description = "Estimated monthly infrastructure cost (USD). Excludes API/token usage."
  value       = format("$%.2f/month — excludes API/token usage", local.estimated_monthly_cost)
}
