variable "name_prefix" {
  description = "Prefix for all resource names"
  type        = string
  default     = "foundry"
}

variable "location" {
  description = "Azure region"
  type        = string
  default     = "swedencentral"
}

variable "enable_private_networking" {
  description = "Enable private networking for all resources"
  type        = bool
  default     = false
}

variable "search_sku" {
  description = "Azure AI Search SKU (basic ~$75/mo, standard ~$250/mo)"
  type        = string
  default     = "standard"
}

variable "enable_redis" {
  description = "Enable Redis for model caching"
  type        = bool
  default     = false
}

variable "enable_apim" {
  description = "Enable API Management"
  type        = bool
  default     = false
}

variable "enable_litellm" {
  description = "Enable LiteLLM proxy"
  type        = bool
  default     = false
}

variable "enable_cosmosdb" {
  description = "Enable Cosmos DB for conversation history and agent state"
  type        = bool
  default     = false
}

variable "cosmosdb_capacity_mode" {
  description = "Cosmos DB capacity mode: 'serverless' (pay-per-use, cheapest) or 'provisioned'"
  type        = string
  default     = "serverless"
}

variable "enable_openclaw" {
  description = "Enable OpenClaw AI coding agent (requires enable_litellm=true)"
  type        = bool
  default     = false
}

variable "openclaw_extra_secrets" {
  description = "Additional secrets for OpenClaw (e.g. {\"anthropic-api-key\" = \"sk-ant-...\"}). Available as secret refs in extra_env."
  type        = map(string)
  default     = {}
  sensitive   = true
}

variable "openclaw_extra_env" {
  description = "Additional env vars for OpenClaw. Set sensitive=true to reference a key from openclaw_extra_secrets."
  type = list(object({
    name      = string
    value     = string
    sensitive = optional(bool, false)
  }))
  default = []
}

variable "allowed_ips" {
  description = "List of IP addresses allowed to access AI Services and Foundry (e.g. [\"95.99.46.198\"]). Empty = allow all."
  type        = list(string)
  default     = []
}

variable "policy_exemption_policy_assignment_id" {
  description = "Policy assignment ID to exempt the Hub from network restriction policies. Leave empty to skip."
  type        = string
  default     = ""
}

variable "alert_email" {
  description = "Email for alert notifications"
  type        = string
  default     = null
}

variable "prevent_deletion_if_contains_resources" {
  description = "Prevent resource group deletion if it contains resources not managed by Terraform. Set to false for teardown."
  type        = bool
  default     = true
}

variable "tags" {
  description = "Additional tags for all resources"
  type        = map(string)
  default     = {}
}

# --- APIM policy stack (citadel-v1 parity, requires enable_apim = true) ---

variable "enable_apim_policies" {
  description = "Deploy the full Azure AI Hub Gateway policy stack (APIs, backends, pools, fragments) on top of APIM. Requires enable_apim = true."
  type        = bool
  default     = false
}

variable "enable_event_hub" {
  description = "Deploy the Event Hubs namespace + usage/PII hubs (required for APIM usage metering policies to function)."
  type        = bool
  default     = false
}

variable "enable_logic_app" {
  description = "Deploy the usage-ingestion Logic App (EH push + App Insights scheduled pull → Cosmos). Requires enable_event_hub + enable_cosmosdb."
  type        = bool
  default     = false
}

variable "apim_policies_foundry_models" {
  description = "Models advertised as the primary Foundry backend's supportedModels. Used to derive backend pools."
  type = list(object({
    name          = string
    model_version = string
    model_format  = optional(string, "OpenAI")
  }))
  default = [
    { name = "gpt-5", model_version = "2025-08-07", model_format = "OpenAI" },
    { name = "text-embedding-3-large", model_version = "1", model_format = "OpenAI" },
  ]
}

variable "apim_policies_enable_azure_openai_api" {
  type    = bool
  default = true
}

variable "apim_policies_enable_universal_llm_api" {
  type    = bool
  default = true
}

variable "apim_policies_enable_unified_ai_api" {
  type    = bool
  default = true
}

variable "apim_policies_enable_ai_model_inference" {
  type    = bool
  default = true
}

variable "apim_policies_enable_openai_realtime" {
  type    = bool
  default = false
}

variable "apim_policies_enable_document_intelligence" {
  type    = bool
  default = false
}

variable "apim_policies_enable_ai_search" {
  type    = bool
  default = false
}

variable "apim_policies_enable_translator" {
  type    = bool
  default = false
}

variable "apim_policies_enable_language" {
  type    = bool
  default = false
}

variable "apim_policies_enable_speech" {
  type    = bool
  default = false
}

variable "apim_policies_enable_pii_anonymization" {
  type    = bool
  default = true
}

variable "apim_policies_enable_mcp_samples" {
  type    = bool
  default = false
}

variable "apim_policies_entra_auth" {
  type    = bool
  default = false
}

variable "apim_policies_entra_tenant_id" {
  type    = string
  default = ""
}

variable "apim_policies_entra_client_id" {
  type    = string
  default = ""
}

variable "apim_policies_entra_audience" {
  type    = string
  default = "https://cognitiveservices.azure.com/.default"
}

variable "apim_policies_enable_jwt_auth" {
  type    = bool
  default = false
}
