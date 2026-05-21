variable "enable_event_hub" {
  description = "Master flag. When false, the module is a no-op."
  type        = bool
  default     = false
}

variable "resource_group_name" {
  description = "Resource group to create the namespace in."
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

variable "sku" {
  description = "Event Hubs SKU (Basic / Standard / Premium)."
  type        = string
  default     = "Standard"

  validation {
    condition     = contains(["Basic", "Standard", "Premium"], var.sku)
    error_message = "sku must be one of: Basic, Standard, Premium."
  }
}

variable "capacity" {
  description = "Throughput units (TUs for Standard/Basic, PUs for Premium)."
  type        = number
  default     = 1
}

variable "auto_inflate_enabled" {
  description = "Enable auto-inflate (Standard only). Ignored for Basic/Premium."
  type        = bool
  default     = false
}

variable "maximum_throughput_units" {
  description = "Maximum TUs when auto-inflate is enabled."
  type        = number
  default     = 5
}

variable "usage_hub_name" {
  description = "Name of the usage event hub (consumed by APIM's usage-eventhub-logger)."
  type        = string
  default     = "usage"
}

variable "pii_hub_name" {
  description = "Name of the PII usage event hub (consumed by APIM's pii-usage-eventhub-logger)."
  type        = string
  default     = "pii-usage"
}

variable "partition_count" {
  description = "Partition count for each hub."
  type        = number
  default     = 4
}

variable "message_retention" {
  description = "Message retention in days for each hub."
  type        = number
  default     = 1
}

variable "enable_private_networking" {
  description = "When true, disable public network access and create a private endpoint."
  type        = bool
  default     = false
}

variable "subnet_id" {
  description = "Subnet ID for the private endpoint (required when enable_private_networking = true)."
  type        = string
  default     = null
}

variable "dns_zone_id" {
  description = "Private DNS zone resource ID for privatelink.servicebus.windows.net."
  type        = string
  default     = null
}

variable "allowed_ips" {
  description = "List of IP addresses allowed to access the namespace when public access is enabled."
  type        = list(string)
  default     = []
}

variable "enable_diagnostics" {
  description = "Send namespace diagnostic settings to log_analytics_workspace_id."
  type        = bool
  default     = true
}

variable "log_analytics_workspace_id" {
  description = "Log Analytics workspace ID for namespace diagnostics. Required when enable_diagnostics = true."
  type        = string
  default     = ""
}

variable "tags" {
  description = "Tags to apply to the namespace and hubs."
  type        = map(string)
  default     = {}
}
