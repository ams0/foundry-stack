locals {
  # Azure AI Foundry Hub auto-creates some role assignments during provisioning
  # (e.g., Hub -> Storage Blob Data Contributor, Hub -> Key Vault Secrets User).
  # We only create assignments that Azure doesn't auto-provision, plus AI Services
  # assignments which are always needed.

  assignments = merge(
    {
      hub_search = {
        scope                = var.search_service_id
        role_definition_name = "Search Index Data Reader"
        principal_id         = var.foundry_hub_principal_id
      }
      ai_storage = {
        scope                = var.storage_account_id
        role_definition_name = "Storage Blob Data Contributor"
        principal_id         = var.ai_services_principal_id
      }
      ai_search_data = {
        scope                = var.search_service_id
        role_definition_name = "Search Index Data Contributor"
        principal_id         = var.ai_services_principal_id
      }
      ai_search_service = {
        scope                = var.search_service_id
        role_definition_name = "Search Service Contributor"
        principal_id         = var.ai_services_principal_id
      }
      ai_keyvault = {
        scope                = var.key_vault_id
        role_definition_name = "Key Vault Secrets User"
        principal_id         = var.ai_services_principal_id
      }
    },
    var.enable_redis ? {
      ai_redis = {
        scope                = var.redis_cache_id
        role_definition_name = "Redis Cache Contributor"
        principal_id         = var.ai_services_principal_id
      }
    } : {},
  )
}

resource "azurerm_role_assignment" "this" {
  for_each = local.assignments

  scope                            = each.value.scope
  role_definition_name             = each.value.role_definition_name
  principal_id                     = each.value.principal_id
  skip_service_principal_aad_check = true
}

resource "azurerm_role_assignment" "additional" {
  for_each = { for idx, ra in var.additional_role_assignments : idx => ra }

  scope                = each.value.scope
  role_definition_name = each.value.role_definition_name
  principal_id         = each.value.principal_id
}
