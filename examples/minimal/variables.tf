variable "name_prefix" {
  description = "Prefix for all resource names"
  type        = string
  default     = "foundry"
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
