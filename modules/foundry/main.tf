locals {
  tags = var.tags

  use_system_identity = var.existing_identity_id == null
}

# --- AI Services ---
# Using azapi_resource because azurerm_ai_services doesn't support
# allowProjectManagement, which is required for the new Foundry portal.

resource "azapi_resource" "ai_services" {
  type      = "Microsoft.CognitiveServices/accounts@2025-04-01-preview"
  name      = "${var.name_prefix}-aiservices"
  location  = var.location
  parent_id = "/subscriptions/${data.azurerm_client_config.current.subscription_id}/resourceGroups/${var.resource_group_name}"
  tags      = local.tags

  identity {
    type = "SystemAssigned"
  }

  body = {
    kind = "AIServices"
    sku = {
      name = "S0"
    }
    properties = {
      customSubDomainName    = "${var.name_prefix}-aiservices"
      publicNetworkAccess    = var.enable_private_networking ? "Disabled" : "Enabled"
      allowProjectManagement = true
      networkAcls = {
        defaultAction = var.enable_private_networking ? "Deny" : "Allow"
        bypass        = "AzureServices"
        ipRules       = [for ip in(var.enable_private_networking ? [] : var.allowed_ips) : { value = ip }]
      }
    }
  }

  response_export_values = ["properties.endpoint", "identity.principalId"]
}

data "azurerm_client_config" "current" {}

# Extract API key from AI Services account
data "azapi_resource_action" "ai_services_keys" {
  type                   = "Microsoft.CognitiveServices/accounts@2024-10-01"
  resource_id            = azapi_resource.ai_services.id
  action                 = "listKeys"
  response_export_values = ["key1"]
}

# --- Model Deployments ---

resource "azurerm_cognitive_deployment" "this" {
  for_each = { for d in var.model_deployments : d.name => d }

  name                 = each.value.name
  cognitive_account_id = azapi_resource.ai_services.id

  model {
    format  = each.value.model_format
    name    = each.value.model_name
    version = each.value.model_version
  }

  sku {
    name     = each.value.sku_name
    capacity = each.value.sku_capacity
  }
}

# --- AI Foundry Hub (legacy portal, optional) ---

resource "azurerm_ai_foundry" "this" {
  count = var.create_hub ? 1 : 0

  name                    = "${var.name_prefix}-hub"
  location                = var.location
  resource_group_name     = var.resource_group_name
  storage_account_id      = var.storage_account_id
  key_vault_id            = var.key_vault_id
  application_insights_id = var.application_insights_id
  public_network_access   = var.enable_private_networking ? "Disabled" : "Enabled"

  identity {
    type         = local.use_system_identity ? "SystemAssigned" : "UserAssigned"
    identity_ids = local.use_system_identity ? null : [var.existing_identity_id]
  }

  # Management group policy may override public_network_access after apply.
  # Ignore it to prevent perpetual drift.
  lifecycle {
    ignore_changes = [public_network_access]
  }

  tags = local.tags
}

# --- Redis connection to Hub ---

resource "azapi_resource" "redis_connection" {
  count = var.create_hub && var.enable_redis ? 1 : 0

  type      = "Microsoft.MachineLearningServices/workspaces/connections@2024-10-01"
  name      = "redis-cache"
  parent_id = azurerm_ai_foundry.this[0].id

  body = {
    properties = {
      category      = "CustomKeys"
      target        = "rediss://${var.redis_cache_hostname}:${var.redis_cache_ssl_port}"
      authType      = "ApiKey"
      isSharedToAll = true
      credentials = {
        key = var.redis_cache_primary_key
      }
      metadata = {
        purpose = "model-caching"
      }
    }
  }
}

# --- Hub Project (legacy portal, optional) ---

resource "azurerm_ai_foundry_project" "this" {
  count = var.create_hub ? 1 : 0

  name               = "${var.name_prefix}-project"
  location           = azurerm_ai_foundry.this[0].location
  ai_services_hub_id = azurerm_ai_foundry.this[0].id

  identity {
    type = "SystemAssigned"
  }

  tags = local.tags
}

# --- Foundry Project (new portal) ---

resource "azurerm_cognitive_account_project" "this" {
  name                 = "${var.name_prefix}-foundry-project"
  cognitive_account_id = azapi_resource.ai_services.id
  location             = var.location
  display_name         = "${var.name_prefix} Project"

  identity {
    type = "SystemAssigned"
  }

  tags = local.tags
}

# --- Policy exemption ---

resource "azurerm_resource_policy_exemption" "hub_public_access" {
  count = var.create_hub && var.policy_exemption_policy_assignment_id != "" ? 1 : 0

  name                 = "${var.name_prefix}-hub-policy-exemption"
  resource_id          = azurerm_ai_foundry.this[0].id
  policy_assignment_id = var.policy_exemption_policy_assignment_id
  exemption_category   = "Waiver"
  description          = "Allow public/IP-restricted network access for AI Foundry Hub"
}
