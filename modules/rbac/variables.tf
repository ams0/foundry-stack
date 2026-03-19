variable "foundry_hub_principal_id" {
  description = "Principal ID of the Foundry Hub managed identity"
  type        = string
}

variable "ai_services_principal_id" {
  description = "Principal ID of the AI Services managed identity"
  type        = string
}

variable "storage_account_id" {
  description = "Storage account resource ID"
  type        = string
}

variable "search_service_id" {
  description = "AI Search service resource ID"
  type        = string
}

variable "key_vault_id" {
  description = "Key Vault resource ID"
  type        = string
}

variable "redis_cache_id" {
  description = "Redis cache resource ID (optional)"
  type        = string
  default     = null
}

variable "enable_redis" {
  description = "Whether Redis role assignments should be created"
  type        = bool
  default     = false
}

variable "additional_role_assignments" {
  description = "Additional custom role assignments"
  type = list(object({
    principal_id         = string
    role_definition_name = string
    scope                = string
  }))
  default = []
}
