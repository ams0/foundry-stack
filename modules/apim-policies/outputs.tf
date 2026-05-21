output "universal_llm_api_id" {
  description = "Resource ID of the universal-llm-api (empty when disabled)."
  value       = var.enable_apim_policies && var.enable_universal_llm_api ? azurerm_api_management_api.universal_llm[0].id : ""
}

output "azure_openai_api_id" {
  description = "Resource ID of the azure-openai-api (empty when disabled)."
  value       = var.enable_apim_policies && var.enable_azure_openai_api ? azurerm_api_management_api.azure_openai[0].id : ""
}

output "unified_ai_api_id" {
  description = "Resource ID of the unified-ai wildcard API (empty when disabled)."
  value       = var.enable_apim_policies && var.enable_unified_ai_api ? azurerm_api_management_api.unified_ai[0].id : ""
}

output "ai_model_inference_api_id" {
  description = "Resource ID of the ai-model-inference API (empty when disabled)."
  value       = var.enable_apim_policies && var.enable_ai_model_inference ? azurerm_api_management_api.ai_model_inference[0].id : ""
}

output "backend_ids" {
  description = "Map of backend_id → APIM backend resource ID."
  value       = { for k, b in azapi_resource.llm_backend : k => b.id }
}

output "backend_pool_ids" {
  description = "Map of pool_name → APIM backend pool resource ID."
  value       = { for k, p in azapi_resource.backend_pool : k => p.id }
}

output "fragment_ids" {
  description = "Map of fragment_name → APIM policy-fragment resource ID."
  value = merge(
    { for k, f in azurerm_api_management_policy_fragment.static : k => f.id },
    { for f in azurerm_api_management_policy_fragment.set_backend_pools : "set-backend-pools" => f.id },
    { for f in azurerm_api_management_policy_fragment.set_backend_authorization : "set-backend-authorization" => f.id },
    { for f in azurerm_api_management_policy_fragment.get_available_models : "get-available-models" => f.id },
    { for f in azurerm_api_management_policy_fragment.metadata_config : "metadata-config" => f.id },
    { for f in azurerm_api_management_policy_fragment.resolve_model_alias : "resolve-model-alias" => f.id },
  )
}

output "unified_ai_product_id" {
  description = "Resource ID of the unified-ai product (empty when disabled)."
  value       = var.enable_apim_policies && var.enable_unified_ai_api ? azurerm_api_management_product.unified_ai[0].id : ""
}
