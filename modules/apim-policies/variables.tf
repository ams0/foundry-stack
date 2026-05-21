variable "enable_apim_policies" {
  description = "Master flag. When false, the module is a no-op."
  type        = bool
  default     = false
}

# --- APIM target ---

variable "api_management_id" {
  description = "Resource ID of the APIM instance to attach to."
  type        = string
}

variable "api_management_name" {
  description = "Name of the APIM instance."
  type        = string
}

variable "resource_group_name" {
  description = "Resource group containing the APIM instance."
  type        = string
}

variable "apim_principal_id" {
  description = "Principal ID (object ID) of the APIM identity used for backend authorization. Used for outputs/diagnostics only."
  type        = string
  default     = ""
}

variable "apim_identity_client_id" {
  description = "Client ID of the APIM user-assigned managed identity used for backend authorization. Leave empty to omit clientId from backend credentials (system-assigned identity)."
  type        = string
  default     = ""
}

variable "application_insights_id" {
  description = "Application Insights resource ID for the appinsights-logger. Leave empty to skip the App Insights logger."
  type        = string
  default     = ""
}

variable "application_insights_connection_string" {
  description = "Application Insights connection string for the appinsights-logger."
  type        = string
  default     = ""
  sensitive   = true
}

# --- LLM backends ---

variable "llm_backends" {
  description = <<-EOT
    List of LLM backends to register in APIM. One azapi backend is created per entry,
    and backend pools are created automatically for any model name supported by 2+ backends.
    Backend auth is managed identity only.

    Each entry:
      backend_id        = unique APIM backend name
      backend_type      = "ai-foundry" | "azure-openai" | "external"
      endpoint          = base URL of the LLM endpoint
      supported_models  = list of model entries: { name, sku?, capacity?, model_format?, model_version?, retirement_date?, api_version?, timeout?, inference_api_version? }
      priority          = optional pool priority (default 1)
      weight            = optional pool weight (default 100)
  EOT
  type = list(object({
    backend_id   = string
    backend_type = string
    endpoint     = string
    supported_models = list(object({
      name                  = string
      sku                   = optional(string, "Standard")
      capacity              = optional(number, 100)
      model_format          = optional(string, "OpenAI")
      model_version         = optional(string, "1")
      retirement_date       = optional(string, "")
      api_version           = optional(string, "2024-02-15-preview")
      timeout               = optional(number, 120)
      inference_api_version = optional(string, "")
    }))
    priority = optional(number, 1)
    weight   = optional(number, 100)
  }))
  default = []
}

variable "configure_circuit_breaker" {
  description = "Whether to configure the per-backend circuit breaker (5xx + 429 → 1m trip)."
  type        = bool
  default     = true
}

# --- Feature flags (mirror citadel main.bicep) ---

variable "enable_azure_openai_api" {
  description = "Deploy the azure-openai-api (AzureOpenAI flavor)."
  type        = bool
  default     = true
}

variable "enable_universal_llm_api" {
  description = "Deploy the universal-llm-api (OpenAIV1 flavor)."
  type        = bool
  default     = true
}

variable "enable_unified_ai_api" {
  description = "Deploy the unified-ai wildcard API + product + deployment operations."
  type        = bool
  default     = true
}

variable "enable_ai_model_inference" {
  description = "Deploy the ai-model-inference API."
  type        = bool
  default     = true
}

variable "enable_openai_realtime" {
  description = "Deploy the WebSocket openai-realtime-ws-api."
  type        = bool
  default     = false
}

variable "enable_document_intelligence" {
  description = "Deploy both Document Intelligence APIs (legacy /formrecognizer + modern /documentintelligence)."
  type        = bool
  default     = false
}

variable "enable_ai_search" {
  description = "Deploy the Azure AI Search index/service APIs."
  type        = bool
  default     = false
}

variable "enable_translator" {
  description = "Deploy the Translator API."
  type        = bool
  default     = false
}

variable "enable_language" {
  description = "Deploy the Language API."
  type        = bool
  default     = false
}

variable "enable_speech" {
  description = "Deploy the Speech API."
  type        = bool
  default     = false
}

variable "enable_pii_anonymization" {
  description = "Create the PII anonymization/deanonymization fragments + state-saving fragment + AI Foundry compatibility fragment."
  type        = bool
  default     = true
}

variable "enable_mcp_samples" {
  description = "Deploy the MCP sample APIs (weather + Microsoft Learn MCP). Off by default — dev only."
  type        = bool
  default     = false
}

# --- Auth / Entra ---

variable "entra_auth" {
  description = "Toggle the 'entra-auth' named value. When true, APIs are deployed with subscription_required=false."
  type        = bool
  default     = false
}

variable "entra_tenant_id" {
  description = "Tenant ID for Entra auth (defaults to current subscription tenant)."
  type        = string
  default     = ""
}

variable "entra_client_id" {
  description = "Entra app registration client ID for the gateway."
  type        = string
  default     = ""
}

variable "entra_audience" {
  description = "Audience value for Entra auth."
  type        = string
  default     = "https://cognitiveservices.azure.com/.default"
}

variable "enable_jwt_auth" {
  description = "Populate the JWT named values used by frag-security-handler. When false, JWT named values are written as 'not-configured'."
  type        = bool
  default     = false
}

variable "jwt_tenant_id" {
  description = "JWT tenant ID. Falls back to entra_tenant_id."
  type        = string
  default     = ""
}

variable "jwt_app_registration_id" {
  description = "JWT app registration client ID."
  type        = string
  default     = ""
}

# --- PII / Content Safety service URLs (referenced from PII fragments) ---

variable "ai_language_service_url" {
  description = "Azure AI Language endpoint used by frag-pii-anonymization (piiServiceUrl named value)."
  type        = string
  default     = ""
}

variable "ai_language_service_key" {
  description = "Azure AI Language key for the piiServiceKey named value. Prefer managed identity."
  type        = string
  default     = "replace-with-language-service-key-if-needed"
  sensitive   = true
}

variable "content_safety_service_url" {
  description = "Content Safety endpoint used by content-safety-backend (referenced from policies)."
  type        = string
  default     = ""
}

# --- Event Hub loggers (optional — needed for usage metering policies) ---

variable "event_hub_logger_name" {
  description = "Event Hub name for the usage-eventhub-logger. Empty disables the EH logger."
  type        = string
  default     = ""
}

variable "event_hub_logger_endpoint" {
  description = "Event Hub namespace endpoint (e.g. https://<ns>.servicebus.windows.net) for the usage-eventhub-logger."
  type        = string
  default     = ""
}

variable "event_hub_pii_logger_name" {
  description = "Event Hub name for the pii-usage-eventhub-logger."
  type        = string
  default     = ""
}

variable "event_hub_pii_logger_endpoint" {
  description = "Event Hub namespace endpoint for the pii-usage-eventhub-logger."
  type        = string
  default     = ""
}

# --- Redis cache (optional) ---

variable "enable_redis_cache" {
  description = "Register an APIM external Redis cache (referenced by semantic-cache policies)."
  type        = bool
  default     = false
}

variable "redis_cache_connection_string" {
  description = "Redis connection string for the APIM external cache."
  type        = string
  default     = ""
  sensitive   = true
}

variable "redis_cache_name" {
  description = "APIM cache entity name."
  type        = string
  default     = "redis-cache"
}

# --- Embeddings backend (optional) ---

variable "enable_embeddings_backend" {
  description = "Create a dedicated embeddings backend (MI auth, targets a /models/embeddings endpoint)."
  type        = bool
  default     = false
}

variable "embeddings_backend_url" {
  description = "URL of the embeddings backend (typically <foundry>/models/embeddings)."
  type        = string
  default     = ""
}

variable "embeddings_backend_id" {
  description = "Backend name for the embeddings backend."
  type        = string
  default     = "foundry-embeddings"
}

# --- Diagnostic settings ---

variable "enable_diagnostics" {
  description = "Send APIM service-level diagnostics to log_analytics_workspace_id."
  type        = bool
  default     = true
}

variable "log_analytics_workspace_id" {
  description = "Log Analytics workspace ID for APIM service-level diagnostic settings. Required when enable_diagnostics = true."
  type        = string
  default     = ""
}

variable "enable_application_insights_logger" {
  description = "Register the APIM Application Insights logger + diagnostic."
  type        = bool
  default     = true
}

variable "enable_event_hub_logger" {
  description = "Register the usage-eventhub-logger. Requires event_hub_logger_name + endpoint."
  type        = bool
  default     = false
}

variable "enable_event_hub_pii_logger" {
  description = "Register the pii-usage-eventhub-logger. Requires event_hub_pii_logger_name + endpoint."
  type        = bool
  default     = false
}

variable "enable_content_safety_backend" {
  description = "Create the content-safety-backend. Requires content_safety_service_url."
  type        = bool
  default     = false
}
