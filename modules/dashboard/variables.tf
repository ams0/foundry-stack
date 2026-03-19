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

variable "log_analytics_workspace_id" {
  description = "Log Analytics workspace resource ID"
  type        = string
}

variable "log_analytics_workspace_name" {
  description = "Log Analytics workspace name"
  type        = string
}

variable "subscription_id" {
  description = "Azure subscription ID"
  type        = string
}

variable "litellm_container_app_name" {
  description = "LiteLLM Container App name for KQL filtering"
  type        = string
}

variable "openclaw_container_app_name" {
  description = "OpenClaw Container App name for KQL filtering"
  type        = string
  default     = ""
}

variable "ai_services_resource_id" {
  description = "AI Services resource ID for metrics"
  type        = string
}

variable "redis_cache_resource_id" {
  description = "Redis Cache resource ID for metrics (optional)"
  type        = string
  default     = null
}

variable "search_service_resource_id" {
  description = "AI Search resource ID for metrics"
  type        = string
}

variable "storage_account_resource_id" {
  description = "Storage Account resource ID for metrics"
  type        = string
}

variable "tags" {
  description = "Tags to apply to resources"
  type        = map(string)
  default     = {}
}
