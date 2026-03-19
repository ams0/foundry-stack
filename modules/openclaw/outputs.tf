output "endpoint_url" {
  description = "OpenClaw web UI endpoint URL"
  value       = var.enable_openclaw ? "https://${azurerm_container_app.this[0].ingress[0].fqdn}" : null
}

output "gateway_token" {
  description = "OpenClaw gateway auth token"
  value       = var.enable_openclaw ? local.gateway_token : null
  sensitive   = true
}

output "provider_config" {
  description = "Generated OpenClaw provider configuration (JSON)"
  value       = var.enable_openclaw ? local.openclaw_provider_config : null
  sensitive   = true
}
