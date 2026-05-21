variable "enable_cosmosdb" {
  description = "Whether to create Cosmos DB resources"
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
  description = "Private DNS zone ID for Cosmos DB"
  type        = string
  default     = null
}

variable "capacity_mode" {
  description = "Cosmos DB capacity mode: 'serverless' (pay-per-use, cheapest) or 'provisioned' (fixed throughput)"
  type        = string
  default     = "serverless"

  validation {
    condition     = contains(["serverless", "provisioned"], var.capacity_mode)
    error_message = "capacity_mode must be 'serverless' or 'provisioned'"
  }
}

variable "provisioned_throughput" {
  description = "Max throughput in RU/s when capacity_mode is 'provisioned' (autoscale). Ignored for serverless."
  type        = number
  default     = 1000
}

variable "databases" {
  description = "Map of database name to list of container configs"
  type = map(list(object({
    name                = string
    partition_key_paths = list(string)
  })))
  default = {
    "foundry" = [
      { name = "conversations", partition_key_paths = ["/userId"] },
      { name = "agent-state", partition_key_paths = ["/agentId"] },
    ]
  }
}

variable "tags" {
  description = "Additional tags to merge with defaults"
  type        = map(string)
  default     = {}
}

# --- Logic App usage-ingestion containers ---

variable "create_logic_app_containers" {
  description = "Create the four containers used by the Logic App usage-ingestion workflows (usage, pii-usage, llm-usage, config) under the logic_app_database."
  type        = bool
  default     = false
}

variable "logic_app_database" {
  description = "Database name to create the Logic App containers under. Created automatically when create_logic_app_containers = true."
  type        = string
  default     = "ai-usage"
}

variable "logic_app_containers" {
  description = "Container name + partition key path for each Logic App container. Names must match Logic App app settings (CosmosDBContainerUsage / *PII / *LLMUsage / *Config)."
  type = map(object({
    name                = string
    partition_key_paths = list(string)
  }))
  default = {
    usage     = { name = "usage", partition_key_paths = ["/subscriptionId"] }
    pii_usage = { name = "pii-usage", partition_key_paths = ["/subscriptionId"] }
    llm_usage = { name = "llm-usage", partition_key_paths = ["/model"] }
    config    = { name = "config", partition_key_paths = ["/id"] }
  }
}
