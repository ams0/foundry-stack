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
  description = "Prefix for all resource names"
  type        = string
}

variable "enable_private_networking" {
  description = "Enable VNet, subnets, NSGs, private DNS zones, and private endpoints"
  type        = bool
  default     = false
}

variable "address_space" {
  description = "VNet address space"
  type        = list(string)
  default     = ["10.0.0.0/16"]
}

variable "subnet_cidrs" {
  description = "CIDR blocks for each service subnet"
  type        = map(string)
  default = {
    foundry  = "10.0.1.0/24"
    storage  = "10.0.2.0/24"
    search   = "10.0.3.0/24"
    redis    = "10.0.4.0/24"
    keyvault = "10.0.5.0/24"
    apim     = "10.0.6.0/24"
    litellm  = "10.0.7.0/24"
    cosmosdb = "10.0.8.0/24"
  }
}

variable "enable_redis" {
  description = "Whether Redis resources are enabled (controls DNS zone creation)"
  type        = bool
  default     = false
}

variable "enable_apim" {
  description = "Whether APIM resources are enabled (controls DNS zone creation)"
  type        = bool
  default     = false
}

variable "enable_litellm" {
  description = "Whether LiteLLM resources are enabled (controls DNS zone creation)"
  type        = bool
  default     = false
}

variable "enable_cosmosdb" {
  description = "Whether Cosmos DB resources are enabled (controls DNS zone creation)"
  type        = bool
  default     = false
}

variable "tags" {
  description = "Additional tags to merge with defaults"
  type        = map(string)
  default     = {}
}
