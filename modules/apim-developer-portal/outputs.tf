output "developer_portal_url" {
  description = "Public URL of the developer portal once published (manual step — see module docs). Returns null when the module is disabled."
  value       = var.enable_developer_portal ? "https://${var.api_management_name}.developer.azure-api.net" : null
}

output "entra_redirect_uris" {
  description = <<-EOT
    Redirect URIs the Entra ID app registration must include under Web platform.
    Add BOTH:
      - /signin     — used by the modern developer portal
      - /signin-aad — used by the legacy/publisher portal
    APIM redirects to either depending on which portal flow the user lands in.
  EOT
  value = var.enable_developer_portal ? [
    "https://${var.api_management_name}.developer.azure-api.net/signin",
    "https://${var.api_management_name}.developer.azure-api.net/signin-aad",
  ] : []
}
