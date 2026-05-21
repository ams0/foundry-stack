# Named values referenced by vendored policy XML.
# Names match citadel-v1 main.bicep exactly so the XMLs work unchanged.

locals {
  named_values = var.enable_apim_policies ? merge(
    {
      "uami-client-id"          = { value = var.apim_identity_client_id != "" ? var.apim_identity_client_id : "systemAssigned", secret = true }
      "entra-auth"              = { value = tostring(var.entra_auth), secret = false }
      "client-id"               = { value = var.entra_client_id != "" ? var.entra_client_id : "not-configured", secret = true }
      "tenant-id"               = { value = var.entra_tenant_id != "" ? var.entra_tenant_id : data.azurerm_client_config.current.tenant_id, secret = true }
      "audience"                = { value = var.entra_audience, secret = true }
      "piiServiceUrl"           = { value = var.ai_language_service_url != "" ? var.ai_language_service_url : "not-configured", secret = false }
      "piiServiceKey"           = { value = var.ai_language_service_key, secret = true }
      "contentSafetyServiceUrl" = { value = var.content_safety_service_url != "" ? var.content_safety_service_url : "not-configured", secret = false }
      "JWT-TenantId"            = { value = local.effective_jwt_tenant_id, secret = false }
      "JWT-AppRegistrationId"   = { value = local.effective_jwt_app_reg_id, secret = false }
      "JWT-Issuer"              = { value = var.enable_jwt_auth ? "${local.entra_login_endpoint}${local.effective_jwt_tenant_id}/v2.0" : "not-configured", secret = false }
      "JWT-OpenIdConfigUrl"     = { value = var.enable_jwt_auth ? "${local.entra_login_endpoint}${local.effective_jwt_tenant_id}/v2.0/.well-known/openid-configuration" : "not-configured", secret = false }
      # AWS Bedrock named values — created with safe defaults so frag-set-backend-authorization compiles.
      "aws-access-key" = { value = "NOT_CONFIGURED", secret = true }
      "aws-secret-key" = { value = "NOT_CONFIGURED", secret = true }
      "aws-region"     = { value = "NOT_CONFIGURED", secret = false }
    },
  ) : {}
}

resource "azurerm_api_management_named_value" "this" {
  for_each = local.named_values

  name                = each.key
  resource_group_name = var.resource_group_name
  api_management_name = var.api_management_name
  display_name        = each.key
  value               = each.value.value
  secret              = each.value.secret
}
