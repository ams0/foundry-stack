variable "resource_group_name" {
  description = "Name of the resource group"
  type        = string
}

variable "location" {
  description = "Azure region"
  type        = string
  default     = "swedencentral"
}

variable "name_prefix" {
  description = "Prefix for resource names"
  type        = string
}

variable "enable_private_networking" {
  description = "Enable private endpoints"
  type        = bool
  default     = false
}

variable "subnet_id" {
  description = "Subnet ID for private endpoints"
  type        = string
  default     = null
}

variable "dns_zone_ids" {
  description = "Map of DNS zone IDs: keys 'cognitiveservices', 'foundry_api', 'foundry_notebooks'"
  type        = map(string)
  default     = {}
}

variable "create_hub" {
  description = "Create the legacy AI Foundry Hub + Hub Project (requires storage_account_id and key_vault_id). When false, only the AI Services account + new-portal project + model deployments are created — useful for additional regional Foundry endpoints behind a gateway."
  type        = bool
  default     = true
}

variable "storage_account_id" {
  description = "Storage account ID to link to Hub. Required when create_hub = true."
  type        = string
  default     = null
}

variable "key_vault_id" {
  description = "Key Vault ID to link to Hub. Required when create_hub = true."
  type        = string
  default     = null
}

variable "application_insights_id" {
  description = "Application Insights ID to link to Hub"
  type        = string
  default     = null
}

variable "enable_redis" {
  description = "Whether to create Redis connection on the Hub"
  type        = bool
  default     = false
}

variable "redis_cache_hostname" {
  description = "Redis cache hostname for Foundry Hub connection (optional)"
  type        = string
  default     = null
}

variable "redis_cache_ssl_port" {
  description = "Redis cache SSL port"
  type        = number
  default     = 6380
}

variable "redis_cache_primary_key" {
  description = "Redis cache primary access key"
  type        = string
  default     = null
  sensitive   = true
}

variable "existing_identity_id" {
  description = "Existing user-assigned identity ID (optional, overrides system-assigned)"
  type        = string
  default     = null
}

variable "model_deployments" {
  description = "List of model deployments to create"
  type = list(object({
    name          = string
    model_name    = string
    model_format  = optional(string, "OpenAI")
    model_version = string
    sku_name      = optional(string, "GlobalStandard")
    sku_capacity  = optional(number, 10)
  }))
  default = [
    {
      name          = "gpt-5"
      model_name    = "gpt-5"
      model_format  = "OpenAI"
      model_version = "2025-08-07"
    },
    {
      name          = "text-embedding-3-large"
      model_name    = "text-embedding-3-large"
      model_format  = "OpenAI"
      model_version = "1"
    },
    {
      name          = "gpt-realtime-1-5"
      model_name    = "gpt-realtime-1.5"
      model_format  = "OpenAI"
      model_version = "2026-02-23"
    },
    {
      name          = "gpt-audio-1-5"
      model_name    = "gpt-audio-1.5"
      model_format  = "OpenAI"
      model_version = "2026-02-23"
    }
  ]
}

variable "allowed_ips" {
  description = "List of IP addresses allowed to access AI Services when not using private networking (e.g. [\"95.99.46.198\"])"
  type        = list(string)
  default     = []
}

variable "policy_exemption_policy_assignment_id" {
  description = "Policy assignment ID to exempt the Hub from (for management group policies that force publicNetworkAccess=Disabled). Leave empty to skip."
  type        = string
  default     = ""
}

variable "tags" {
  description = "Additional tags to merge with defaults"
  type        = map(string)
  default     = {}
}
