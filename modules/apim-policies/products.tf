# Unified AI product (subscription-based, API Key auth)

resource "azurerm_api_management_product" "unified_ai" {
  count = var.enable_apim_policies && var.enable_unified_ai_api ? 1 : 0

  product_id            = "unified-ai-product"
  resource_group_name   = var.resource_group_name
  api_management_name   = var.api_management_name
  display_name          = "Unified AI Gateway"
  description           = "Unified AI Gateway product — provides access to all AI model providers through a single wildcard endpoint."
  subscription_required = true
  approval_required     = false
  subscriptions_limit   = 10
  published             = true
}

resource "azurerm_api_management_product_api" "unified_ai" {
  count = var.enable_apim_policies && var.enable_unified_ai_api ? 1 : 0

  product_id          = azurerm_api_management_product.unified_ai[0].product_id
  api_name            = azurerm_api_management_api.unified_ai[0].name
  resource_group_name = var.resource_group_name
  api_management_name = var.api_management_name
}

resource "azurerm_api_management_product_policy" "unified_ai" {
  count = var.enable_apim_policies && var.enable_unified_ai_api ? 1 : 0

  product_id          = azurerm_api_management_product.unified_ai[0].product_id
  resource_group_name = var.resource_group_name
  api_management_name = var.api_management_name
  xml_content         = file("${local.policies_path}/unified-ai-product-subscription.xml")
}

# LLM OAuth product — only when JWT auth is enabled (the policy references JWT named values).

resource "azurerm_api_management_product" "llm_oauth" {
  count = var.enable_apim_policies && var.enable_jwt_auth ? 1 : 0

  product_id            = "llm-oauth-access"
  resource_group_name   = var.resource_group_name
  api_management_name   = var.api_management_name
  display_name          = "LLM OAuth Access"
  description           = "Subscription-less, JWT-authenticated access product for LLM APIs."
  subscription_required = false
  published             = true
}

resource "azurerm_api_management_product_policy" "llm_oauth" {
  count = var.enable_apim_policies && var.enable_jwt_auth ? 1 : 0

  product_id          = azurerm_api_management_product.llm_oauth[0].product_id
  resource_group_name = var.resource_group_name
  api_management_name = var.api_management_name
  xml_content         = file("${local.policies_path}/product-llm-oauth-access.xml")
}
