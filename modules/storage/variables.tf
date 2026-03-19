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
  description = "Subnet ID for private endpoint (required if enable_private_networking=true)"
  type        = string
  default     = null
}

variable "dns_zone_ids" {
  description = "Map of DNS zone IDs: keys 'blob' and 'dfs'"
  type        = map(string)
  default     = {}
}

variable "account_replication_type" {
  description = "Storage account replication type"
  type        = string
  default     = "LRS"
}

variable "account_tier" {
  description = "Storage account tier"
  type        = string
  default     = "Standard"
}

variable "containers" {
  description = "List of blob containers to create"
  type        = list(string)
  default     = ["documents", "chunks", "embeddings", "models"]
}

variable "tags" {
  description = "Additional tags to merge with defaults"
  type        = map(string)
  default     = {}
}
