variable "name_prefix" {
  description = "Prefix for all resource names"
  type        = string
  default     = "foundry"
}

variable "location" {
  description = "Azure region for shared resources (RG, storage, KV, search, monitoring, APIM, legacy Hub). Must be one of foundry_regions, and is treated as the primary."
  type        = string
  default     = "swedencentral"
}

variable "foundry_regions" {
  description = "List of Azure regions to deploy Foundry AI Services accounts to. var.location must appear in this list and is the primary (gets the legacy Hub + storage/KV/search; APIM routes to it with priority 1). Additional regions get an AI Services account + new-portal project + model deployments only (priority 2+, used for failover/region pin via APIM)."
  type        = list(string)
  default     = ["swedencentral", "northeurope"]

  validation {
    condition     = length(var.foundry_regions) >= 1
    error_message = "foundry_regions must contain at least one region."
  }
}

variable "enable_private_networking" {
  description = "Enable private networking for all resources"
  type        = bool
  default     = false
}

variable "search_sku" {
  description = "Azure AI Search SKU (basic ~$75/mo, standard ~$250/mo)"
  type        = string
  default     = "standard"
}

variable "enable_redis" {
  description = "Enable Redis for model caching"
  type        = bool
  default     = false
}

variable "enable_apim" {
  description = "Enable API Management"
  type        = bool
  default     = false
}

variable "enable_developer_portal" {
  description = "Publish the APIM developer portal at https://<apim>.developer.azure-api.net (Entra-ID-only sign-in). Requires enable_apim = true."
  type        = bool
  default     = false
}

variable "enable_apim_products" {
  description = "Create APIM products + a demo subscription so signed-in dev-portal users can see/subscribe to the LLM APIs. Requires enable_apim = true."
  type        = bool
  default     = false
}

variable "developer_portal_entra" {
  description = <<-EOT
    Entra ID app registration credentials for the developer portal. Required when enable_developer_portal = true
    if you want users to be able to sign in. The app registration needs a Web platform redirect URI of
    https://<apim>.developer.azure-api.net/signin-aad (see module output `developer_portal_entra_redirect_uri`).
    Leave null to publish the portal without an IdP — sign-in will be required but unusable until you configure
    one in the Azure portal.
  EOT
  type = object({
    client_id       = string
    client_secret   = string
    allowed_tenants = list(string)
  })
  default   = null
  sensitive = true
}

variable "enable_litellm" {
  description = "Enable LiteLLM proxy"
  type        = bool
  default     = false
}

variable "enable_cosmosdb" {
  description = "Enable Cosmos DB for conversation history and agent state"
  type        = bool
  default     = false
}

variable "cosmosdb_capacity_mode" {
  description = "Cosmos DB capacity mode: 'serverless' (pay-per-use, cheapest) or 'provisioned'"
  type        = string
  default     = "serverless"
}

variable "enable_openclaw" {
  description = "Enable OpenClaw AI coding agent (requires enable_litellm=true)"
  type        = bool
  default     = false
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

variable "allowed_ips" {
  description = "List of IP addresses allowed to access AI Services and Foundry (e.g. [\"95.99.46.198\"]). Empty = allow all."
  type        = list(string)
  default     = []
}

variable "policy_exemption_policy_assignment_id" {
  description = "Policy assignment ID to exempt the Hub from network restriction policies. Leave empty to skip."
  type        = string
  default     = ""
}

variable "alert_email" {
  description = "Email for alert notifications"
  type        = string
  default     = null
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
