# --- Static policy fragments (loaded verbatim from policies/) ---

locals {
  static_fragments_always = var.enable_apim_policies ? {
    "ai-usage" = {
      file        = "frag-ai-usage.xml"
      description = "Tracks usage of all AI-related APIs with flexible dimensions for models, features, and more"
    }
    "raise-throttling-events" = {
      file        = "frag-raise-throttling-events.xml"
      description = "Raises custom events when throttling limits are hit through App Insights metrics, for proactive monitoring and alerting"
    }
    "pii-anonymization" = {
      file        = "frag-pii-anonymization.xml"
      description = "Anonymizes personally identifiable information (PII) in API requests"
    }
    "pii-deanonymization" = {
      file        = "frag-pii-deanonymization.xml"
      description = "Deanonymizes personally identifiable information (PII) in API responses when needed for backend processing"
    }
    "security-handler" = {
      file        = "frag-security-handler.xml"
      description = "Unified authentication handler for all AI Gateway APIs (API Key + optional JWT per-product)"
    }
    "strip-backend-headers" = {
      file        = "frag-strip-backend-headers.xml"
      description = "Removes browser, App Service / ARR, and X-Forwarded-* headers from requests forwarded to AI backends"
    }
    "set-target-backend-pool" = {
      file        = "frag-set-target-backend-pool.xml"
      description = "Determines the target backend pool for LLM requests"
    }
    "set-llm-usage" = {
      file        = "frag-set-llm-usage.xml"
      description = "Collects usage metrics for LLM requests"
    }
    "set-llm-requested-model" = {
      file        = "frag-set-llm-requested-model.xml"
      description = "Extracts the requested model from deployment-id (Azure OpenAI) or request body (Inference)"
    }
    "validate-model-access" = {
      file        = "frag-validate-model-access.xml"
      description = "Validates that the requested model is in the allowed models list for the product"
    }
    "responses-id-security" = {
      file        = "frag-responses-id-security.xml"
      description = "Inbound: validates response_id ownership and hydrates routing for /responses operations"
    }
    "responses-id-cache-store" = {
      file        = "frag-responses-id-cache-store.xml"
      description = "Outbound: caches response_id ownership for newly created Responses API objects"
    }
  } : {}

  static_fragments_pii = var.enable_apim_policies && var.enable_pii_anonymization ? {
    "pii-state-saving" = {
      file        = "frag-pii-state-saving.xml"
      description = "Saves the state of personally identifiable information (PII) for testing & validation purposes"
    }
    "ai-foundry-compatibility" = {
      file        = "frag-ai-foundry-compatibility.xml"
      description = "Ensures compatibility with Microsoft Foundry CORS requirements"
    }
  } : {}

  static_fragments_unified = var.enable_apim_policies && var.enable_unified_ai_api ? {
    "central-cache-manager" = {
      file        = "frag-central-cache-manager.xml"
      description = "Caches metadata configuration for Unified AI API performance"
    }
    "request-processor" = {
      file        = "frag-request-processor.xml"
      description = "Analyzes incoming Unified AI requests to extract routing context"
    }
    "path-builder" = {
      file        = "frag-path-builder.xml"
      description = "Reconstructs backend URI paths for Unified AI API routing"
    }
    "set-response-headers" = {
      file        = "frag-set-response-headers.xml"
      description = "Adds UAIG-* response headers when enableResponseHeaders is true"
    }
  } : {}

  static_fragments = merge(
    local.static_fragments_always,
    local.static_fragments_pii,
    local.static_fragments_unified,
  )
}

resource "azurerm_api_management_policy_fragment" "static" {
  for_each = local.static_fragments

  name              = each.key
  api_management_id = var.api_management_id
  format            = "rawxml"
  description       = each.value.description
  value             = file("${local.policies_path}/${each.value.file}")

  depends_on = [
    azurerm_api_management_named_value.this,
    azapi_resource.eventhub_logger,
    azapi_resource.eventhub_pii_logger,
  ]
}

# --- Dynamic fragments (C# code spliced in via local replace) ---

locals {
  set_backend_pools_xml = var.enable_apim_policies ? replace(
    file("${local.policies_path}/frag-set-backend-pools.xml"),
    "//{backendPoolsCode}",
    local.backend_pools_code,
  ) : ""

  get_available_models_xml = var.enable_apim_policies ? replace(
    file("${local.policies_path}/frag-get-available-models.xml"),
    "//{modelDeploymentsCode}",
    local.model_deployments_code,
  ) : ""

  metadata_config_xml = var.enable_apim_policies ? replace(
    file("${local.policies_path}/frag-metadata-config.xml"),
    "//{modelsConfigCode}",
    local.metadata_models_code,
  ) : ""

  resolve_model_alias_xml = var.enable_apim_policies ? replace(
    file("${local.policies_path}/frag-resolve-model-alias.xml"),
    "//{inlineAliasesCode}",
    "",
  ) : ""
}

resource "azurerm_api_management_policy_fragment" "set_backend_pools" {
  count = var.enable_apim_policies ? 1 : 0

  name              = "set-backend-pools"
  api_management_id = var.api_management_id
  format            = "rawxml"
  description       = "Dynamically generated backend pool configurations for LLM routing"
  value             = local.set_backend_pools_xml
}

resource "azurerm_api_management_policy_fragment" "set_backend_authorization" {
  count = var.enable_apim_policies ? 1 : 0

  name              = "set-backend-authorization"
  api_management_id = var.api_management_id
  format            = "rawxml"
  description       = "Authentication and routing configuration for different LLM backend types"
  value             = file("${local.policies_path}/frag-set-backend-authorization.xml")

  depends_on = [azurerm_api_management_named_value.this]
}

resource "azurerm_api_management_policy_fragment" "get_available_models" {
  count = var.enable_apim_policies ? 1 : 0

  name              = "get-available-models"
  api_management_id = var.api_management_id
  format            = "rawxml"
  description       = "Returns a JSON response listing all available model deployments with their capabilities"
  value             = local.get_available_models_xml
}

resource "azurerm_api_management_policy_fragment" "metadata_config" {
  count = var.enable_apim_policies ? 1 : 0

  name              = "metadata-config"
  api_management_id = var.api_management_id
  format            = "rawxml"
  description       = "Dynamically generated metadata configuration for Unified AI API routing"
  value             = local.metadata_config_xml
}

resource "azurerm_api_management_policy_fragment" "resolve_model_alias" {
  count = var.enable_apim_policies ? 1 : 0

  name              = "resolve-model-alias"
  api_management_id = var.api_management_id
  format            = "rawxml"
  description       = "Resolves model alias names to actual underlying models with priority/weighted strategy"
  value             = local.resolve_model_alias_xml
}
