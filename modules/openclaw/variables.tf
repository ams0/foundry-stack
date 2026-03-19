variable "enable_openclaw" {
  description = "Whether to create OpenClaw resources"
  type        = bool
  default     = false
}

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

variable "create_own_environment" {
  description = "Whether to create its own Container App Environment (false = shared with LiteLLM)"
  type        = bool
  default     = false
}

variable "container_app_environment_id" {
  description = "Existing Container App Environment ID (shared with LiteLLM)"
  type        = string
  default     = null
}

variable "enable_private_networking" {
  description = "Enable private networking"
  type        = bool
  default     = false
}

variable "subnet_id" {
  description = "Subnet ID for Container App environment (only used if creating own environment)"
  type        = string
  default     = null
}

variable "gateway_token" {
  description = "OpenClaw gateway auth token. Auto-generated if empty."
  type        = string
  default     = ""
  sensitive   = true
}

variable "litellm_endpoint" {
  description = "LiteLLM proxy endpoint URL"
  type        = string
}

variable "litellm_api_key" {
  description = "LiteLLM API key for authentication"
  type        = string
  default     = ""
  sensitive   = true
}

variable "model_config" {
  description = "Model configuration for OpenClaw's LiteLLM provider"
  type = list(object({
    id             = string
    name           = string
    reasoning      = optional(bool, false)
    context_window = optional(number, 128000)
    max_tokens     = optional(number, 128000)
  }))
  default = [
    {
      id             = "gpt-5"
      name           = "GPT-5 (Azure/LiteLLM)"
      reasoning      = false
      context_window = 128000
      max_tokens     = 128000
    }
  ]
}

variable "image" {
  description = "OpenClaw container image"
  type        = string
  default     = "ghcr.io/openclaw/openclaw:latest"
}

variable "cpu" {
  description = "CPU cores for the container"
  type        = number
  default     = 1.0
}

variable "memory" {
  description = "Memory for the container"
  type        = string
  default     = "2Gi"
}

variable "allowed_origins" {
  description = "List of allowed CORS origins for the gateway"
  type        = list(string)
  default     = ["app://localhost"]
}

variable "extra_secrets" {
  description = "Map of additional secrets (name => value) to inject into the container. These become available as secret references."
  type        = map(string)
  default     = {}
  sensitive   = true
}

variable "extra_env" {
  description = "List of additional environment variables. Set sensitive=true to reference from extra_secrets."
  type = list(object({
    name      = string
    value     = string
    sensitive = optional(bool, false)
  }))
  default = []
}

variable "tags" {
  description = "Tags to apply to resources"
  type        = map(string)
  default     = {}
}
