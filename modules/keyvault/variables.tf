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
  description = "Enable private endpoint and deny public access"
  type        = bool
  default     = false
}

variable "subnet_id" {
  description = "Subnet ID for private endpoint"
  type        = string
  default     = null
}

variable "dns_zone_id" {
  description = "Private DNS zone ID for Key Vault"
  type        = string
  default     = null
}

variable "soft_delete_retention_days" {
  description = "Number of days to retain soft-deleted vaults"
  type        = number
  default     = 90
}

variable "tags" {
  description = "Additional tags to merge with defaults"
  type        = map(string)
  default     = {}
}
