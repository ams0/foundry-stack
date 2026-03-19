variable "enable_apim" {
  description = "Whether to create APIM resources"
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
  description = "Private DNS zone ID for APIM"
  type        = string
  default     = null
}

variable "foundry_endpoint" {
  description = "AI Foundry endpoint URL for API backend"
  type        = string
  default     = ""
}

variable "sku_name" {
  description = "APIM SKU"
  type        = string
  default     = "Developer_1"
}

variable "publisher_name" {
  description = "APIM publisher name"
  type        = string
  default     = "AI Platform Team"
}

variable "publisher_email" {
  description = "APIM publisher email"
  type        = string
  default     = "admin@example.com"
}

variable "tags" {
  description = "Additional tags to merge with defaults"
  type        = map(string)
  default     = {}
}
