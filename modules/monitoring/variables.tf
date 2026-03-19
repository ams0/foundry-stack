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

variable "retention_days" {
  description = "Log Analytics workspace retention in days"
  type        = number
  default     = 30
}

variable "alert_email" {
  description = "Email address for alert notifications (optional)"
  type        = string
  default     = null
}

variable "resource_ids" {
  description = "Map of resource name to resource ID for diagnostic settings"
  type        = map(string)
  default     = {}
}

variable "enable_redis" {
  description = "Whether Redis alerts should be created"
  type        = bool
  default     = false
}

variable "tags" {
  description = "Additional tags to merge with defaults"
  type        = map(string)
  default     = {}
}
