variable "enable_logic_app" {
  description = "Master flag. When false, the module is a no-op."
  type        = bool
  default     = false
}

variable "resource_group_name" {
  description = "Resource group."
  type        = string
}

variable "location" {
  description = "Azure region."
  type        = string
}

variable "name_prefix" {
  description = "Prefix for resource names."
  type        = string
}

variable "sku_name" {
  description = "App Service plan SKU (WS1 / WS2 / WS3)."
  type        = string
  default     = "WS1"
}

# --- Dependencies (Event Hub + Cosmos + App Insights) ---

variable "event_hub_namespace_fqdn" {
  description = "Event Hubs namespace FQDN (e.g. <ns>.servicebus.windows.net)."
  type        = string
}

variable "event_hub_usage_name" {
  description = "Event Hub name for usage events (consumed by ai-usage-ingestion + ai-usage-streaming-ingestion workflows)."
  type        = string
}

variable "event_hub_pii_name" {
  description = "Event Hub name for PII events (consumed by pii-usage-ingestion workflow)."
  type        = string
}

variable "cosmos_account_endpoint" {
  description = "Cosmos DB account endpoint URL (https://<account>.documents.azure.com:443/)."
  type        = string
}

variable "cosmos_database_name" {
  description = "Cosmos DB SQL database hosting the four containers."
  type        = string
}

variable "cosmos_container_usage" {
  description = "Container name for raw usage events."
  type        = string
  default     = "usage"
}

variable "cosmos_container_pii" {
  description = "Container name for PII events."
  type        = string
  default     = "pii-usage"
}

variable "cosmos_container_llm_usage" {
  description = "Container name for scheduled-aggregation LLM usage docs."
  type        = string
  default     = "llm-usage"
}

variable "cosmos_container_config" {
  description = "Container name for the scheduler cursor / config doc."
  type        = string
  default     = "config"
}

variable "application_insights_name" {
  description = "Application Insights resource name (used by scheduled KQL queries)."
  type        = string
}

variable "application_insights_resource_group" {
  description = "Resource group of the Application Insights instance."
  type        = string
}

variable "application_insights_subscription_id" {
  description = "Subscription ID of the Application Insights instance."
  type        = string
}

variable "application_insights_connection_string" {
  description = "App Insights connection string for the Logic App's own telemetry."
  type        = string
  default     = ""
  sensitive   = true
}

# --- Optional networking + diagnostics ---

variable "enable_private_networking" {
  description = "Enable VNet integration + private endpoint."
  type        = bool
  default     = false
}

variable "subnet_id" {
  description = "Subnet ID for VNet integration / private endpoint."
  type        = string
  default     = null
}

variable "dns_zone_id" {
  description = "Private DNS zone ID for privatelink.azurewebsites.net."
  type        = string
  default     = null
}

variable "enable_diagnostics" {
  description = "Send Logic App diagnostic settings to log_analytics_workspace_id. Requires log_analytics_workspace_id to be set."
  type        = bool
  default     = true
}

variable "log_analytics_workspace_id" {
  description = "Log Analytics workspace ID for diagnostics. Required when enable_diagnostics = true."
  type        = string
  default     = ""
}

variable "tags" {
  description = "Tags to apply to all resources."
  type        = map(string)
  default     = {}
}
