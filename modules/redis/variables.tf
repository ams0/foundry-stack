variable "enable_redis" {
  description = "Whether to create Redis resources"
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
  description = "Subnet ID for private endpoint"
  type        = string
  default     = null
}

variable "dns_zone_id" {
  description = "Private DNS zone ID for Redis"
  type        = string
  default     = null
}

variable "sku_name" {
  description = "Redis SKU name"
  type        = string
  default     = "Standard"
}

variable "family" {
  description = "Redis family"
  type        = string
  default     = "C"
}

variable "capacity" {
  description = "Redis cache capacity"
  type        = number
  default     = 1
}

variable "tags" {
  description = "Additional tags to merge with defaults"
  type        = map(string)
  default     = {}
}
