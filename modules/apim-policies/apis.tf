# Every API definition + API-level policy + operation policies.
# Resource shapes mirror citadel inference-api.bicep / api.bicep.

locals {
  api_subscription_required = !var.entra_auth

  # Common dependencies for any API-level policy: all fragments must exist first.
  fragment_dep = compact(concat(
    [for f in azurerm_api_management_policy_fragment.static : f.id],
    [for f in azurerm_api_management_policy_fragment.set_backend_pools : f.id],
    [for f in azurerm_api_management_policy_fragment.set_backend_authorization : f.id],
    [for f in azurerm_api_management_policy_fragment.get_available_models : f.id],
    [for f in azurerm_api_management_policy_fragment.metadata_config : f.id],
    [for f in azurerm_api_management_policy_fragment.resolve_model_alias : f.id],
  ))
}

# ---------- Universal LLM API (OpenAIV1 contract, /models) ----------

resource "azurerm_api_management_api" "universal_llm" {
  count = var.enable_apim_policies && var.enable_universal_llm_api ? 1 : 0

  name                  = "universal-llm-api"
  resource_group_name   = var.resource_group_name
  api_management_name   = var.api_management_name
  revision              = "1"
  display_name          = "Universal LLM API"
  description           = "Universal LLM API to route requests to different LLM providers including Azure OpenAI, AI Foundry and 3rd party models."
  path                  = "models"
  protocols             = ["https"]
  subscription_required = local.api_subscription_required

  subscription_key_parameter_names {
    header = "api-key"
    query  = "api-key"
  }

  import {
    content_format = "openapi+json"
    content_value  = file("${local.apis_path}/universal-llm/AIFoundryOpenAIV1.json")
  }
}

resource "azurerm_api_management_api_policy" "universal_llm" {
  count = var.enable_apim_policies && var.enable_universal_llm_api ? 1 : 0

  api_name            = azurerm_api_management_api.universal_llm[0].name
  resource_group_name = var.resource_group_name
  api_management_name = var.api_management_name
  xml_content         = file("${local.policies_path}/universal-llm-api-policy-v2.xml")

  depends_on = [
    azurerm_api_management_policy_fragment.static,
    azurerm_api_management_policy_fragment.set_backend_pools,
    azurerm_api_management_policy_fragment.set_backend_authorization,
    azurerm_api_management_policy_fragment.get_available_models,
    azurerm_api_management_policy_fragment.metadata_config,
    azurerm_api_management_policy_fragment.resolve_model_alias,
  ]
}

# Operation policies: deployments + deployment-by-name + listModels + retrieveModel
resource "azurerm_api_management_api_operation_policy" "universal_llm_deployments" {
  count = var.enable_apim_policies && var.enable_universal_llm_api ? 1 : 0

  api_name            = azurerm_api_management_api.universal_llm[0].name
  resource_group_name = var.resource_group_name
  api_management_name = var.api_management_name
  operation_id        = "deployments"
  xml_content         = file("${local.policies_path}/universal-llm-api-deployments-policy.xml")

  depends_on = [azurerm_api_management_api_policy.universal_llm]
}

resource "azurerm_api_management_api_operation_policy" "universal_llm_deployment_by_name" {
  count = var.enable_apim_policies && var.enable_universal_llm_api ? 1 : 0

  api_name            = azurerm_api_management_api.universal_llm[0].name
  resource_group_name = var.resource_group_name
  api_management_name = var.api_management_name
  operation_id        = "deployment-by-name"
  xml_content         = file("${local.policies_path}/universal-llm-api-deployment-by-name-policy.xml")

  depends_on = [azurerm_api_management_api_policy.universal_llm]
}

resource "azurerm_api_management_api_operation_policy" "universal_llm_list_models" {
  count = var.enable_apim_policies && var.enable_universal_llm_api ? 1 : 0

  api_name            = azurerm_api_management_api.universal_llm[0].name
  resource_group_name = var.resource_group_name
  api_management_name = var.api_management_name
  operation_id        = "listModels"
  xml_content         = file("${local.policies_path}/universal-llm-api-deployments-policy.xml")

  depends_on = [azurerm_api_management_api_policy.universal_llm]
}

resource "azurerm_api_management_api_operation_policy" "universal_llm_retrieve_model" {
  count = var.enable_apim_policies && var.enable_universal_llm_api ? 1 : 0

  api_name            = azurerm_api_management_api.universal_llm[0].name
  resource_group_name = var.resource_group_name
  api_management_name = var.api_management_name
  operation_id        = "retrieveModel"
  xml_content         = file("${local.policies_path}/universal-llm-api-deployment-by-name-policy.xml")

  depends_on = [azurerm_api_management_api_policy.universal_llm]
}

# ---------- Azure OpenAI API (AzureOpenAI contract, /openai) ----------

resource "azurerm_api_management_api" "azure_openai" {
  count = var.enable_apim_policies && var.enable_azure_openai_api ? 1 : 0

  name                  = "azure-openai-api"
  resource_group_name   = var.resource_group_name
  api_management_name   = var.api_management_name
  revision              = "1"
  display_name          = "Azure OpenAI API"
  description           = "Azure OpenAI API to route requests to different LLM providers including Azure OpenAI, AI Foundry and 3rd party models."
  path                  = "openai"
  protocols             = ["https"]
  subscription_required = local.api_subscription_required

  subscription_key_parameter_names {
    header = "api-key"
    query  = "api-key"
  }

  import {
    content_format = "openapi+json"
    content_value  = file("${local.apis_path}/universal-llm/AIFoundryOpenAI.json")
  }
}

resource "azurerm_api_management_api_policy" "azure_openai" {
  count = var.enable_apim_policies && var.enable_azure_openai_api ? 1 : 0

  api_name            = azurerm_api_management_api.azure_openai[0].name
  resource_group_name = var.resource_group_name
  api_management_name = var.api_management_name
  xml_content         = file("${local.policies_path}/azure-open-ai-api-policy.xml")

  depends_on = [
    azurerm_api_management_policy_fragment.static,
    azurerm_api_management_policy_fragment.set_backend_pools,
    azurerm_api_management_policy_fragment.set_backend_authorization,
    azurerm_api_management_policy_fragment.get_available_models,
    azurerm_api_management_policy_fragment.metadata_config,
    azurerm_api_management_policy_fragment.resolve_model_alias,
  ]
}

resource "azurerm_api_management_api_operation_policy" "azure_openai_deployments" {
  count = var.enable_apim_policies && var.enable_azure_openai_api ? 1 : 0

  api_name            = azurerm_api_management_api.azure_openai[0].name
  resource_group_name = var.resource_group_name
  api_management_name = var.api_management_name
  operation_id        = "deployments"
  xml_content         = file("${local.policies_path}/universal-llm-api-deployments-policy.xml")

  depends_on = [azurerm_api_management_api_policy.azure_openai]
}

resource "azurerm_api_management_api_operation_policy" "azure_openai_deployment_by_name" {
  count = var.enable_apim_policies && var.enable_azure_openai_api ? 1 : 0

  api_name            = azurerm_api_management_api.azure_openai[0].name
  resource_group_name = var.resource_group_name
  api_management_name = var.api_management_name
  operation_id        = "deployment-by-name"
  xml_content         = file("${local.policies_path}/universal-llm-api-deployment-by-name-policy.xml")

  depends_on = [azurerm_api_management_api_policy.azure_openai]
}

# ---------- AI Model Inference API ----------

resource "azurerm_api_management_api" "ai_model_inference" {
  count = var.enable_apim_policies && var.enable_ai_model_inference ? 1 : 0

  name                  = "ai-model-inference-api"
  resource_group_name   = var.resource_group_name
  api_management_name   = var.api_management_name
  revision              = "1"
  display_name          = "AI Model Inference API"
  description           = "Azure AI Model Inference contract — unified inference surface across providers."
  path                  = "ai-model-inference"
  protocols             = ["https"]
  subscription_required = local.api_subscription_required

  subscription_key_parameter_names {
    header = "api-key"
    query  = "api-key"
  }

  import {
    content_format = "openapi"
    content_value  = file("${local.apis_path}/model-inference/ai-model-inference.yaml")
  }
}

resource "azurerm_api_management_api_policy" "ai_model_inference" {
  count = var.enable_apim_policies && var.enable_ai_model_inference ? 1 : 0

  api_name            = azurerm_api_management_api.ai_model_inference[0].name
  resource_group_name = var.resource_group_name
  api_management_name = var.api_management_name
  xml_content         = file("${local.policies_path}/ai-model-inference-api-policy.xml")

  depends_on = [
    azurerm_api_management_policy_fragment.static,
    azurerm_api_management_policy_fragment.set_backend_pools,
    azurerm_api_management_policy_fragment.set_backend_authorization,
  ]
}

# ---------- Unified AI Wildcard API (own product + ops) ----------

resource "azurerm_api_management_api" "unified_ai" {
  count = var.enable_apim_policies && var.enable_unified_ai_api ? 1 : 0

  name                  = "unified-ai-api"
  resource_group_name   = var.resource_group_name
  api_management_name   = var.api_management_name
  revision              = "1"
  display_name          = "Unified AI API"
  description           = "Unified AI Gateway API — routes requests to multiple AI model providers using dynamic path-based routing."
  path                  = "unified-ai"
  protocols             = ["https"]
  subscription_required = true

  subscription_key_parameter_names {
    header = "api-key"
    query  = "api-key"
  }

  import {
    content_format = "openapi+json"
    content_value  = file("${local.apis_path}/unified-ai/UnifiedAIWildcard.json")
  }
}

resource "azurerm_api_management_api_policy" "unified_ai" {
  count = var.enable_apim_policies && var.enable_unified_ai_api ? 1 : 0

  api_name            = azurerm_api_management_api.unified_ai[0].name
  resource_group_name = var.resource_group_name
  api_management_name = var.api_management_name
  xml_content         = file("${local.policies_path}/unified-ai-api-policy.xml")

  depends_on = [
    azurerm_api_management_policy_fragment.static,
    azurerm_api_management_policy_fragment.set_backend_pools,
    azurerm_api_management_policy_fragment.set_backend_authorization,
    azurerm_api_management_policy_fragment.get_available_models,
    azurerm_api_management_policy_fragment.metadata_config,
    azurerm_api_management_policy_fragment.resolve_model_alias,
  ]
}

resource "azurerm_api_management_api_operation_policy" "unified_ai_deployments" {
  count = var.enable_apim_policies && var.enable_unified_ai_api ? 1 : 0

  api_name            = azurerm_api_management_api.unified_ai[0].name
  resource_group_name = var.resource_group_name
  api_management_name = var.api_management_name
  operation_id        = "deployments"
  xml_content         = file("${local.policies_path}/unified-ai-api-deployments-policy.xml")

  depends_on = [azurerm_api_management_api_policy.unified_ai]
}

resource "azurerm_api_management_api_operation_policy" "unified_ai_deployment_by_name" {
  count = var.enable_apim_policies && var.enable_unified_ai_api ? 1 : 0

  api_name            = azurerm_api_management_api.unified_ai[0].name
  resource_group_name = var.resource_group_name
  api_management_name = var.api_management_name
  operation_id        = "deployment-by-name"
  xml_content         = file("${local.policies_path}/unified-ai-api-deployment-by-name-policy.xml")

  depends_on = [azurerm_api_management_api_policy.unified_ai]
}

# ---------- OpenAI Realtime (WebSocket) ----------

# WebSocket APIs need to be created via azapi because azurerm doesn't expose apiType=websocket.
resource "azapi_resource" "openai_realtime_api" {
  count = var.enable_apim_policies && var.enable_openai_realtime ? 1 : 0

  type      = "Microsoft.ApiManagement/service/apis@2024-06-01-preview"
  name      = "openai-realtime-ws-api"
  parent_id = var.api_management_id

  body = {
    properties = {
      path                 = "openai/realtime"
      apiRevision          = "1"
      description          = "Access Azure OpenAI Realtime API for real-time voice and text conversion."
      displayName          = "Azure OpenAI Realtime API"
      subscriptionRequired = local.api_subscription_required
      subscriptionKeyParameterNames = {
        header = "api-key"
      }
      type       = "websocket"
      protocols  = ["wss"]
      serviceUrl = "wss://to-be-replaced-by-policy"
    }
  }
}

# WebSocket policies must be attached to the onHandshake operation.
resource "azapi_resource" "openai_realtime_handshake_policy" {
  count = var.enable_apim_policies && var.enable_openai_realtime ? 1 : 0

  type      = "Microsoft.ApiManagement/service/apis/operations/policies@2024-06-01-preview"
  name      = "policy"
  parent_id = "${azapi_resource.openai_realtime_api[0].id}/operations/onHandshake"

  body = {
    properties = {
      format = "rawxml"
      value  = file("${local.policies_path}/openai-realtime-policy.xml")
    }
  }

  depends_on = [
    azurerm_api_management_policy_fragment.static,
    azurerm_api_management_policy_fragment.set_backend_authorization,
  ]
}

# ---------- Document Intelligence (legacy + modern) ----------

resource "azurerm_api_management_api" "doc_intel_legacy" {
  count = var.enable_apim_policies && var.enable_document_intelligence ? 1 : 0

  name                  = "document-intelligence-api-legacy"
  resource_group_name   = var.resource_group_name
  api_management_name   = var.api_management_name
  revision              = "1"
  display_name          = "Document Intelligence API (Legacy)"
  description           = "Uses (/formrecognizer) url path. Extracts content, layout, and structured data from documents."
  path                  = "formrecognizer"
  protocols             = ["https"]
  subscription_required = local.api_subscription_required

  subscription_key_parameter_names {
    header = "Ocp-Apim-Subscription-Key"
    query  = "subscription-key"
  }

  import {
    content_format = "openapi"
    content_value  = file("${local.apis_path}/doc-intel/document-intelligence-2024-11-30.yaml")
  }
}

resource "azurerm_api_management_api_policy" "doc_intel_legacy" {
  count = var.enable_apim_policies && var.enable_document_intelligence ? 1 : 0

  api_name            = azurerm_api_management_api.doc_intel_legacy[0].name
  resource_group_name = var.resource_group_name
  api_management_name = var.api_management_name
  xml_content         = file("${local.policies_path}/doc-intelligence-api-policy.xml")

  depends_on = [azurerm_api_management_policy_fragment.static]
}

resource "azurerm_api_management_api" "doc_intel" {
  count = var.enable_apim_policies && var.enable_document_intelligence ? 1 : 0

  name                  = "document-intelligence-api"
  resource_group_name   = var.resource_group_name
  api_management_name   = var.api_management_name
  revision              = "1"
  display_name          = "Document Intelligence API"
  description           = "Uses (/documentintelligence) url path. Extracts content, layout, and structured data from documents."
  path                  = "documentintelligence"
  protocols             = ["https"]
  subscription_required = local.api_subscription_required

  subscription_key_parameter_names {
    header = "Ocp-Apim-Subscription-Key"
    query  = "subscription-key"
  }

  import {
    content_format = "openapi"
    content_value  = file("${local.apis_path}/doc-intel/document-intelligence-2024-11-30.yaml")
  }
}

resource "azurerm_api_management_api_policy" "doc_intel" {
  count = var.enable_apim_policies && var.enable_document_intelligence ? 1 : 0

  api_name            = azurerm_api_management_api.doc_intel[0].name
  resource_group_name = var.resource_group_name
  api_management_name = var.api_management_name
  xml_content         = file("${local.policies_path}/doc-intelligence-api-policy.xml")

  depends_on = [azurerm_api_management_policy_fragment.static]
}

# ---------- AI Search (index + service) ----------

resource "azurerm_api_management_api" "ai_search_index" {
  count = var.enable_apim_policies && var.enable_ai_search ? 1 : 0

  name                  = "azure-ai-search-index-api"
  resource_group_name   = var.resource_group_name
  api_management_name   = var.api_management_name
  revision              = "1"
  display_name          = "Azure AI Search Index API (index services)"
  description           = "Azure AI Search Index Client APIs"
  path                  = "search"
  protocols             = ["https"]
  subscription_required = local.api_subscription_required

  subscription_key_parameter_names {
    header = "api-key"
    query  = "api-key"
  }

  import {
    content_format = "openapi+json"
    content_value  = file("${local.apis_path}/ai-search/ai-search-index.json")
  }
}

resource "azurerm_api_management_api_policy" "ai_search_index" {
  count = var.enable_apim_policies && var.enable_ai_search ? 1 : 0

  api_name            = azurerm_api_management_api.ai_search_index[0].name
  resource_group_name = var.resource_group_name
  api_management_name = var.api_management_name
  xml_content         = file("${local.policies_path}/ai-search-index-api-policy.xml")

  depends_on = [azurerm_api_management_policy_fragment.static]
}

resource "azurerm_api_management_api" "ai_search_service" {
  count = var.enable_apim_policies && var.enable_ai_search ? 1 : 0

  name                  = "azure-ai-search-service-api"
  resource_group_name   = var.resource_group_name
  api_management_name   = var.api_management_name
  revision              = "1"
  display_name          = "Azure AI Search Service API"
  description           = "Azure AI Search Service management APIs"
  path                  = "search-service"
  protocols             = ["https"]
  subscription_required = local.api_subscription_required

  subscription_key_parameter_names {
    header = "api-key"
    query  = "api-key"
  }

  import {
    content_format = "openapi+json"
    content_value  = file("${local.apis_path}/ai-search/ai-search-service.json")
  }
}

resource "azurerm_api_management_api_policy" "ai_search_service" {
  count = var.enable_apim_policies && var.enable_ai_search ? 1 : 0

  api_name            = azurerm_api_management_api.ai_search_service[0].name
  resource_group_name = var.resource_group_name
  api_management_name = var.api_management_name
  xml_content         = file("${local.policies_path}/ai-search-service-api-policy.xml")

  depends_on = [azurerm_api_management_policy_fragment.static]
}

# ---------- Translator / Language / Speech ----------

resource "azurerm_api_management_api" "translator" {
  count = var.enable_apim_policies && var.enable_translator ? 1 : 0

  name                  = "translator-api"
  resource_group_name   = var.resource_group_name
  api_management_name   = var.api_management_name
  revision              = "1"
  display_name          = "Azure AI Translator API"
  description           = "Azure AI Translator service APIs"
  path                  = "translator"
  protocols             = ["https"]
  subscription_required = local.api_subscription_required

  subscription_key_parameter_names {
    header = "Ocp-Apim-Subscription-Key"
    query  = "subscription-key"
  }

  import {
    content_format = "openapi"
    content_value  = file("${local.apis_path}/translator/translator.yaml")
  }
}

resource "azurerm_api_management_api_policy" "translator" {
  count = var.enable_apim_policies && var.enable_translator ? 1 : 0

  api_name            = azurerm_api_management_api.translator[0].name
  resource_group_name = var.resource_group_name
  api_management_name = var.api_management_name
  xml_content         = file("${local.policies_path}/translator-api-policy.xml")

  depends_on = [azurerm_api_management_policy_fragment.static]
}

resource "azurerm_api_management_api" "language" {
  count = var.enable_apim_policies && var.enable_language ? 1 : 0

  name                  = "language-api"
  resource_group_name   = var.resource_group_name
  api_management_name   = var.api_management_name
  revision              = "1"
  display_name          = "Azure AI Language API"
  description           = "Azure AI Language service APIs"
  path                  = "language"
  protocols             = ["https"]
  subscription_required = local.api_subscription_required

  subscription_key_parameter_names {
    header = "Ocp-Apim-Subscription-Key"
    query  = "subscription-key"
  }

  import {
    content_format = "openapi+json"
    content_value  = file("${local.apis_path}/language/language-2024-11-01.json")
  }
}

resource "azurerm_api_management_api" "speech" {
  count = var.enable_apim_policies && var.enable_speech ? 1 : 0

  name                  = "speech-api"
  resource_group_name   = var.resource_group_name
  api_management_name   = var.api_management_name
  revision              = "1"
  display_name          = "Azure AI Speech API"
  description           = "Azure AI Speech service APIs"
  path                  = "speech"
  protocols             = ["https"]
  subscription_required = local.api_subscription_required

  subscription_key_parameter_names {
    header = "Ocp-Apim-Subscription-Key"
    query  = "subscription-key"
  }

  import {
    content_format = "openapi+json"
    content_value  = file("${local.apis_path}/speech/speech-3-1.json")
  }
}

# ---------- MCP samples (off by default) ----------

resource "azurerm_api_management_api" "weather" {
  count = var.enable_apim_policies && var.enable_mcp_samples ? 1 : 0

  name                  = "weather-api"
  resource_group_name   = var.resource_group_name
  api_management_name   = var.api_management_name
  revision              = "1"
  display_name          = "Weather API"
  description           = "Weather API for getting dynamic weather information for a given location."
  path                  = "weather"
  protocols             = ["https"]
  subscription_required = false

  subscription_key_parameter_names {
    header = "api-key"
    query  = "api-key"
  }

  import {
    content_format = "openapi+json"
    content_value  = file("${local.apis_path}/weather/openapi.json")
  }
}

resource "azurerm_api_management_api_policy" "weather" {
  count = var.enable_apim_policies && var.enable_mcp_samples ? 1 : 0

  api_name            = azurerm_api_management_api.weather[0].name
  resource_group_name = var.resource_group_name
  api_management_name = var.api_management_name
  xml_content         = file("${local.apis_path}/weather/policy.xml")
}

# Microsoft Learn MCP server (existing-backend MCP via azapi)
resource "azapi_resource" "ms_learn_mcp_backend" {
  count = var.enable_apim_policies && var.enable_mcp_samples ? 1 : 0

  type      = "Microsoft.ApiManagement/service/backends@2024-06-01-preview"
  name      = "ms-learn-mcp-server"
  parent_id = var.api_management_id

  body = {
    properties = {
      description = "Microsoft Learn MCP Server"
      url         = "https://learn.microsoft.com/api/mcp"
      protocol    = "http"
      tls = {
        validateCertificateChain = true
        validateCertificateName  = true
      }
    }
  }
}
