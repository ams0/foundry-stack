variable "enable_litellm" {
  description = "Whether to create LiteLLM resources"
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

variable "enable_private_networking" {
  description = "Enable private endpoint"
  type        = bool
  default     = false
}

variable "subnet_id" {
  description = "Subnet ID for Container App environment"
  type        = string
  default     = null
}

variable "dns_zone_id" {
  description = "Private DNS zone ID for Container Apps"
  type        = string
  default     = null
}

variable "log_analytics_workspace_id" {
  description = "Log Analytics workspace ID to send Container App logs to"
  type        = string
  default     = null
}

variable "foundry_endpoint" {
  description = "AI Foundry endpoint URL (e.g. https://<name>.cognitiveservices.azure.com/)"
  type        = string
  default     = ""
}

variable "api_version" {
  description = "Azure OpenAI API version"
  type        = string
  default     = "2024-12-01-preview"
}

variable "master_key" {
  description = "LiteLLM master API key for proxy authentication. Auto-generated if empty."
  type        = string
  default     = ""
  sensitive   = true
}

variable "model_deployments" {
  description = "List of Azure model deployments to expose via LiteLLM"
  type = list(object({
    model_name      = string
    deployment_name = string
  }))
  default = [
    { model_name = "gpt-5", deployment_name = "gpt-5" },
    { model_name = "text-embedding-3-large", deployment_name = "text-embedding-3-large" },
  ]
}

variable "cpu" {
  description = "CPU cores for the container"
  type        = number
  default     = 0.5
}

variable "memory" {
  description = "Memory in Gi for the container"
  type        = string
  default     = "1Gi"
}

variable "min_replicas" {
  description = "Minimum number of replicas"
  type        = number
  default     = 1
}

variable "max_replicas" {
  description = "Maximum number of replicas"
  type        = number
  default     = 3
}

variable "tags" {
  description = "Additional tags to merge with defaults"
  type        = map(string)
  default     = {}
}
