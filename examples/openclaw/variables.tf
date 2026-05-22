variable "name_prefix" {
  description = "Prefix for all resource names"
  type        = string
  default     = "openclaw"
}

variable "location" {
  description = "Azure region"
  type        = string
  default     = "swedencentral"
}

variable "enable_private_networking" {
  description = "Enable private networking for all resources"
  type        = bool
  default     = false
}

variable "allowed_ips" {
  description = "List of IP addresses allowed to access AI Services and Foundry. Empty = allow all public access."
  type        = list(string)
  default     = []
}

variable "openclaw_extra_secrets" {
  description = "Additional secrets for OpenClaw (e.g. {\"anthropic-api-key\" = \"sk-ant-...\"}). Available as secret refs in extra_env."
  type        = map(string)
  default     = {}
  sensitive   = true
}

variable "openclaw_extra_env" {
  description = "Additional env vars for OpenClaw. Set sensitive=true to reference a key from openclaw_extra_secrets."
  type = list(object({
    name      = string
    value     = string
    sensitive = optional(bool, false)
  }))
  default = []
}

variable "prevent_deletion_if_contains_resources" {
  description = "Prevent resource group deletion if it contains resources not managed by Terraform. Set to false for teardown."
  type        = bool
  default     = true
}

variable "tags" {
  description = "Additional tags for all resources"
  type        = map(string)
  default     = {}
}
