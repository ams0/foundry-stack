variable "enable_developer_portal" {
  description = "Master flag. When false, the module is a no-op."
  type        = bool
  default     = false
}

variable "api_management_id" {
  description = "Resource ID of the APIM instance."
  type        = string
}

variable "api_management_name" {
  description = "Name of the APIM instance."
  type        = string
}

variable "resource_group_name" {
  description = "Resource group containing the APIM instance."
  type        = string
}

variable "require_signin" {
  description = "Require sign-in for ALL portal access (no anonymous browsing). When true, the portal redirects unauthenticated visitors to the sign-in page."
  type        = bool
  default     = true
}

variable "enable_signup" {
  description = <<-EOT
    Allow new APIM user accounts to be provisioned. Required when signing in via a federated IdP
    (e.g. Entra ID) for the FIRST time — the "Complete sign up" form submits to this endpoint to
    create the local APIM user. Disabling this also blocks first-time federated users.

    Note: with no Basic identity provider registered, this still won't expose username/password
    self-registration — only IdP-initiated provisioning.
  EOT
  type    = bool
  default = true
}

variable "terms_of_service" {
  description = "Optional Terms of Service text shown during sign-up. Empty disables the consent step."
  type        = string
  default     = ""
}

variable "entra_identity_provider" {
  description = <<-EOT
    Optional Entra ID identity provider configuration. When set, registers an AAD identity provider
    so users can sign in with their organisational account. Leave null to skip (sign-in is still
    required but unusable until you configure an identity provider in the Azure portal).

    Requires an Entra app registration with:
      - Web platform redirect URI: https://<apim-name>.developer.azure-api.net/signin-aad
      - A client secret
      - (Optional) ID tokens enabled under Authentication > Implicit grant for the legacy flow
  EOT
  type = object({
    client_id       = string
    client_secret   = string
    allowed_tenants = list(string)
    signin_tenant   = optional(string)
    authority       = optional(string, "login.microsoftonline.com")
  })
  default   = null
  sensitive = true
}

variable "notification_emails" {
  description = "Additional email addresses to receive APIM portal notifications (new subscriptions, etc.)."
  type        = list(string)
  default     = []
}
