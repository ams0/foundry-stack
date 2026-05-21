output "namespace_id" {
  description = "Event Hubs namespace resource ID."
  value       = var.enable_event_hub ? azurerm_eventhub_namespace.this[0].id : null
}

output "namespace_name" {
  description = "Event Hubs namespace name."
  value       = var.enable_event_hub ? azurerm_eventhub_namespace.this[0].name : null
}

output "namespace_endpoint" {
  description = "Event Hubs namespace endpoint (https://<namespace>.servicebus.windows.net)."
  value       = var.enable_event_hub ? "https://${azurerm_eventhub_namespace.this[0].name}.servicebus.windows.net" : null
}

output "namespace_fqdn" {
  description = "Event Hubs namespace FQDN without scheme (<namespace>.servicebus.windows.net)."
  value       = var.enable_event_hub ? "${azurerm_eventhub_namespace.this[0].name}.servicebus.windows.net" : null
}

output "usage_hub_name" {
  description = "Name of the usage event hub."
  value       = var.enable_event_hub ? azurerm_eventhub.usage[0].name : null
}

output "pii_hub_name" {
  description = "Name of the PII usage event hub."
  value       = var.enable_event_hub ? azurerm_eventhub.pii[0].name : null
}
