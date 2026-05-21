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
