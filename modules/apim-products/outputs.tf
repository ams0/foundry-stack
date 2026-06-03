output "product_ids" {
  description = "Map of product name → APIM product resource ID."
  value       = { for k, v in azurerm_api_management_product.this : k => v.id }
}

output "subscription_keys" {
  description = "Map of '<product>|<subscription_id>' → primary key. Sensitive."
  value = {
    for k, v in azurerm_api_management_subscription.this : k => v.primary_key
  }
  sensitive = true
}

output "subscription_ids" {
  description = "Map of '<product>|<subscription_id>' → subscription resource ID (non-sensitive)."
  value       = { for k, v in azurerm_api_management_subscription.this : k => v.id }
}
