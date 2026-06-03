data "azurerm_client_config" "current" {}

resource "random_string" "suffix" {
  length  = 4
  special = false
  upper   = false
}

locals {
  name_prefix = "${var.name_prefix}-${random_string.suffix.result}"
  tags = merge({
    SecurityControl = "Ignore"
    CostControl     = "Ignore"
  }, var.tags)

  # var.location is the primary region (shared resources + Hub live here).
  # All other entries in foundry_regions get AI Services + new-portal project only.
  primary_region = var.location

  # Short region codes — used in per-region resource names so we stay under
  # the 33-char limit on AI Foundry Hub names. Unknown regions fall through to
  # their full name (caller may need to add a short code for very long ones).
  region_short_codes = {
    swedencentral  = "sc"
    northeurope    = "ne"
    westeurope     = "we"
    francecentral  = "fc"
    eastus         = "eus"
    eastus2        = "eus2"
    westus         = "wus"
    westus2        = "wus2"
    westus3        = "wus3"
    northcentralus = "ncus"
    southcentralus = "scus"
    centralus      = "cus"
    uksouth        = "uks"
    ukwest         = "ukw"
    japaneast      = "jape"
    australiaeast  = "aue"
    eastasia       = "easia"
    southeastasia  = "seasia"
  }

  # Model set deployed in every Foundry region. Kept narrow so APIM auto-creates
  # backend pools (which only happens when ≥2 backends advertise the same model).
  foundry_models = [
    {
      name          = "gpt-5"
      model_name    = "gpt-5"
      model_format  = "OpenAI"
      model_version = "2025-08-07"
    },
    {
      name          = "text-embedding-3-large"
      model_name    = "text-embedding-3-large"
      model_format  = "OpenAI"
      model_version = "1"
    },
  ]

  # Estimated monthly costs (USD) for Sweden Central region.
  # Base infrastructure only — API/token usage costs are not included.
  # Additional Foundry regions cost $0/mo base (AI Services S0 + GlobalStandard deployments are pay-per-use).
  estimated_costs = {
    ai_search             = var.search_sku == "basic" ? 75.14 : 249.46
    storage_account       = 5.00
    key_vault             = 3.00
    log_analytics         = 7.50
    application_insights  = 0.00
    ai_foundry_hub        = 0.00
    ai_services_s0        = 0.00
    gpt5_deployment       = 0.00
    redis_standard_c1     = 81.76
    apim_developer        = 48.36
    litellm_container_app = 32.00
    cosmosdb_serverless   = 0.00
    cosmosdb_provisioned  = 24.00
    openclaw_container    = 64.00
  }

  monthly_cost_base = (
    local.estimated_costs["ai_search"] +
    local.estimated_costs["storage_account"] +
    local.estimated_costs["key_vault"] +
    local.estimated_costs["log_analytics"]
  )

  monthly_cost_optional = (
    (var.enable_redis ? local.estimated_costs["redis_standard_c1"] : 0) +
    (var.enable_apim ? local.estimated_costs["apim_developer"] : 0) +
    (var.enable_litellm ? local.estimated_costs["litellm_container_app"] : 0) +
    (var.enable_cosmosdb ? (var.cosmosdb_capacity_mode == "serverless" ? local.estimated_costs["cosmosdb_serverless"] : local.estimated_costs["cosmosdb_provisioned"]) : 0) +
    (var.enable_openclaw ? local.estimated_costs["openclaw_container"] : 0)
  )

  monthly_cost_total = local.monthly_cost_base + local.monthly_cost_optional
}

# Guard: primary location must be in foundry_regions.
check "primary_region_in_foundry_regions" {
  assert {
    condition     = contains(var.foundry_regions, var.location)
    error_message = "var.location (${var.location}) must appear in var.foundry_regions (${join(",", var.foundry_regions)})."
  }
}

resource "azurerm_resource_group" "this" {
  name     = "${local.name_prefix}-rg"
  location = var.location
  tags     = local.tags
}

# --- Networking ---

module "networking" {
  source = "../../modules/networking"

  resource_group_name       = azurerm_resource_group.this.name
  location                  = var.location
  name_prefix               = local.name_prefix
  enable_private_networking = var.enable_private_networking
  enable_redis              = var.enable_redis
  enable_apim               = var.enable_apim
  enable_litellm            = var.enable_litellm
  enable_cosmosdb           = var.enable_cosmosdb
  tags                      = local.tags
}

# --- Monitoring ---

module "monitoring" {
  source = "../../modules/monitoring"

  resource_group_name = azurerm_resource_group.this.name
  location            = var.location
  name_prefix         = local.name_prefix
  alert_email         = var.alert_email
  enable_redis        = var.enable_redis
  tags                = local.tags

  # Note: Foundry/APIM diagnostics created separately below to avoid circular deps
  resource_ids = merge(
    {
      storage  = module.storage.storage_account_id
      search   = module.search.search_service_id
      keyvault = module.keyvault.key_vault_id
    },
    var.enable_redis ? { redis = module.redis.redis_cache_id } : {},
  )
}

# --- Data Layer ---

module "storage" {
  source = "../../modules/storage"

  resource_group_name       = azurerm_resource_group.this.name
  location                  = var.location
  name_prefix               = local.name_prefix
  enable_private_networking = var.enable_private_networking
  subnet_id                 = try(module.networking.subnet_ids["storage"], null)
  dns_zone_ids = {
    blob = try(module.networking.dns_zone_ids["blob"], "")
    dfs  = try(module.networking.dns_zone_ids["dfs"], "")
  }
  tags = local.tags
}

module "search" {
  source = "../../modules/search"

  resource_group_name       = azurerm_resource_group.this.name
  location                  = var.location
  name_prefix               = local.name_prefix
  enable_private_networking = var.enable_private_networking
  subnet_id                 = try(module.networking.subnet_ids["search"], null)
  dns_zone_id               = try(module.networking.dns_zone_ids["search"], null)
  sku                       = var.search_sku
  tags                      = local.tags
}

module "redis" {
  source = "../../modules/redis"

  enable_redis              = var.enable_redis
  resource_group_name       = azurerm_resource_group.this.name
  location                  = var.location
  name_prefix               = local.name_prefix
  enable_private_networking = var.enable_private_networking
  subnet_id                 = try(module.networking.subnet_ids["redis"], null)
  dns_zone_id               = try(module.networking.dns_zone_ids["redis"], null)
  tags                      = local.tags
}

module "keyvault" {
  source = "../../modules/keyvault"

  resource_group_name       = azurerm_resource_group.this.name
  location                  = var.location
  name_prefix               = local.name_prefix
  enable_private_networking = var.enable_private_networking
  subnet_id                 = try(module.networking.subnet_ids["keyvault"], null)
  dns_zone_id               = try(module.networking.dns_zone_ids["keyvault"], null)
  tags                      = local.tags
}

module "cosmosdb" {
  source = "../../modules/cosmosdb"

  enable_cosmosdb           = var.enable_cosmosdb
  resource_group_name       = azurerm_resource_group.this.name
  location                  = var.location
  name_prefix               = local.name_prefix
  enable_private_networking = var.enable_private_networking
  subnet_id                 = try(module.networking.subnet_ids["cosmosdb"], null)
  dns_zone_id               = try(module.networking.dns_zone_ids["cosmosdb"], null)
  capacity_mode             = var.cosmosdb_capacity_mode
  tags                      = local.tags
}

# --- AI Layer (multi-region) ---
#
# One Foundry instance per region in var.foundry_regions:
#   - primary region (var.location): full Foundry — AI Services + new-portal project + legacy Hub + Hub project
#   - additional regions: AI Services + new-portal project + model deployments only (no Hub)
#
# APIM (below) routes across all regional AI Services endpoints.

module "foundry" {
  source   = "../../modules/foundry"
  for_each = toset(var.foundry_regions)

  resource_group_name       = azurerm_resource_group.this.name
  location                  = each.value
  name_prefix               = "${local.name_prefix}-${lookup(local.region_short_codes, each.value, each.value)}"
  create_hub                = each.value == local.primary_region
  enable_private_networking = var.enable_private_networking
  subnet_id                 = try(module.networking.subnet_ids["foundry"], null)
  dns_zone_ids = {
    cognitiveservices = try(module.networking.dns_zone_ids["cognitiveservices"], "")
    foundry_api       = try(module.networking.dns_zone_ids["foundry_api"], "")
    foundry_notebooks = try(module.networking.dns_zone_ids["foundry_notebooks"], "")
  }

  # Hub-only inputs (passed for primary region; null for others)
  storage_account_id                    = each.value == local.primary_region ? module.storage.storage_account_id : null
  key_vault_id                          = each.value == local.primary_region ? module.keyvault.key_vault_id : null
  application_insights_id               = each.value == local.primary_region ? module.monitoring.application_insights_id : null
  policy_exemption_policy_assignment_id = each.value == local.primary_region ? var.policy_exemption_policy_assignment_id : ""
  enable_redis                          = each.value == local.primary_region ? var.enable_redis : false
  redis_cache_hostname                  = module.redis.hostname
  redis_cache_primary_key               = module.redis.primary_access_key

  allowed_ips       = var.allowed_ips
  model_deployments = local.foundry_models
  tags              = local.tags
}

# RBAC for the primary Foundry: Hub + AI Services principals get access
# to the shared storage / search / KV. Secondary regions only host AI Services
# accounts (no Hub) and don't access shared data services.
module "rbac" {
  source = "../../modules/rbac"

  foundry_hub_principal_id = module.foundry[local.primary_region].hub_principal_id
  ai_services_principal_id = module.foundry[local.primary_region].ai_services_principal_id
  storage_account_id       = module.storage.storage_account_id
  search_service_id        = module.search.search_service_id
  key_vault_id             = module.keyvault.key_vault_id
  redis_cache_id           = module.redis.redis_cache_id
  enable_redis             = var.enable_redis
}

# --- Diagnostic settings for resources created after monitoring ---

resource "azurerm_monitor_diagnostic_setting" "foundry" {
  for_each = module.foundry

  name                       = "foundry-diag-${each.key}"
  target_resource_id         = each.value.ai_services_id
  log_analytics_workspace_id = module.monitoring.log_analytics_workspace_id

  enabled_log {
    category_group = "allLogs"
  }

  enabled_metric {
    category = "AllMetrics"
  }
}

# --- Gateway Layer (optional) ---

module "apim" {
  source = "../../modules/apim"

  enable_apim               = var.enable_apim
  resource_group_name       = azurerm_resource_group.this.name
  location                  = var.location
  name_prefix               = local.name_prefix
  enable_private_networking = var.enable_private_networking
  subnet_id                 = try(module.networking.subnet_ids["apim"], null)
  dns_zone_id               = try(module.networking.dns_zone_ids["apim"], null)
  foundry_endpoint          = module.foundry[local.primary_region].ai_services_endpoint
  tags                      = local.tags
}

# Grant APIM's system-assigned identity Cognitive Services OpenAI User
# on each regional AI Services account so MI-auth backends can call them.
resource "azurerm_role_assignment" "apim_cognitive" {
  for_each = var.enable_apim ? toset(var.foundry_regions) : toset([])

  scope                            = module.foundry[each.value].ai_services_id
  role_definition_name             = "Cognitive Services OpenAI User"
  principal_id                     = module.apim.principal_id
  skip_service_principal_aad_check = true
}

# Event Hub for APIM usage logging. The apim-policies module's ai-usage policy
# fragment references usage-eventhub-logger; that logger only exists when
# enable_event_hub_logger = true, which in turn requires a real Event Hub.
module "event_hub" {
  source = "../../modules/event-hub"

  enable_event_hub           = var.enable_apim
  resource_group_name        = azurerm_resource_group.this.name
  location                   = var.location
  name_prefix                = local.name_prefix
  sku                        = "Standard"
  capacity                   = 1
  log_analytics_workspace_id = module.monitoring.log_analytics_workspace_id
  tags                       = local.tags
}

# Grant APIM's system-assigned identity Azure Event Hubs Data Sender on the
# namespace so the usage logger can publish via managed identity.
resource "azurerm_role_assignment" "apim_eventhub_sender" {
  count = var.enable_apim ? 1 : 0

  scope                            = module.event_hub.namespace_id
  role_definition_name             = "Azure Event Hubs Data Sender"
  principal_id                     = module.apim.principal_id
  skip_service_principal_aad_check = true
}

# Full AI Hub Gateway policy stack: per-region backends with circuit breakers
# + auto backend pools (priority 1 = primary, 2 = secondary regions) for any
# model exposed by ≥2 backends. APIM picks the lowest-priority healthy backend
# and fails over to higher priorities on 5xx/429.
module "apim_policies" {
  source = "../../modules/apim-policies"

  enable_apim_policies                   = var.enable_apim
  api_management_id                      = module.apim.id
  api_management_name                    = module.apim.name
  resource_group_name                    = azurerm_resource_group.this.name
  apim_principal_id                      = module.apim.principal_id
  application_insights_id                = module.monitoring.application_insights_id
  application_insights_connection_string = module.monitoring.application_insights_connection_string
  log_analytics_workspace_id             = module.monitoring.log_analytics_workspace_id

  llm_backends = [
    for region in var.foundry_regions : {
      backend_id   = "foundry-${region}"
      backend_type = "ai-foundry"
      endpoint     = module.foundry[region].ai_services_endpoint
      priority     = region == local.primary_region ? 1 : 2
      weight       = 100
      supported_models = [
        for m in local.foundry_models : {
          name          = m.name
          model_format  = m.model_format
          model_version = m.model_version
        }
      ]
    }
  ]

  # Event Hub loggers — required because ai-usage / llm-usage / pii-state-saving
  # fragments reference these loggers. APIM rejects fragment creation when the
  # referenced logger doesn't exist.
  enable_event_hub_logger       = var.enable_apim
  event_hub_logger_name         = module.event_hub.usage_hub_name
  event_hub_logger_endpoint     = module.event_hub.namespace_endpoint
  enable_event_hub_pii_logger   = var.enable_apim
  event_hub_pii_logger_name     = module.event_hub.pii_hub_name
  event_hub_pii_logger_endpoint = module.event_hub.namespace_endpoint

  # PII fragments stay on: the universal-llm / unified-ai API policies include
  # the `ai-foundry-compatibility` fragment unconditionally, which is gated on
  # this flag in the module. Disable JWT/MCP samples to keep things lean.
  enable_pii_anonymization = true
  enable_jwt_auth          = false

  depends_on = [
    azurerm_role_assignment.apim_cognitive,
    azurerm_role_assignment.apim_eventhub_sender,
  ]
}

# --- Service-level policy: stamp subscription-owner email into telemetry ---
#
# APIM auto-populates `context.User` when subscription-key auth is used AND
# the subscription has an ownerId (i.e. it was created via the dev portal by
# a signed-in user). We emit a <trace> with the owner email/name as metadata
# items, which land in App Insights' `traces` table as custom dimensions and
# are correlated to the matching `requests` row via operation_Id.
#
# Query example:
#   traces
#   | where customDimensions["Message Source"] == "user-attribution"
#   | extend email = tostring(customDimensions.userEmail)
#   | summarize calls = count() by email, tostring(customDimensions.productName)
#
# For Terraform-baked subscriptions (e.g. the demo-key) context.User is null,
# so the email column shows "anonymous".

resource "azurerm_api_management_policy" "global_user_attribution" {
  count = var.enable_apim ? 1 : 0

  api_management_id = module.apim.id
  xml_content       = <<-EOT
    <policies>
      <inbound>
        <trace source="user-attribution" severity="information">
          <message>API call user attribution</message>
          <metadata name="userEmail" value="@(context.User?.Email ?? "anonymous")" />
          <metadata name="userId" value="@(context.User?.Id ?? "anonymous")" />
          <metadata name="userFirstName" value="@(context.User?.FirstName ?? "")" />
          <metadata name="userLastName" value="@(context.User?.LastName ?? "")" />
          <metadata name="subscriptionId" value="@(context.Subscription?.Id ?? "no-sub")" />
          <metadata name="subscriptionName" value="@(context.Subscription?.Name ?? "no-sub")" />
          <metadata name="productName" value="@(context.Product?.Name ?? "no-product")" />
        </trace>
        <set-header name="X-Owner-Email" exists-action="override">
          <value>@(context.User?.Email ?? "anonymous")</value>
        </set-header>
      </inbound>
      <backend />
      <outbound />
      <on-error />
    </policies>
  EOT

  depends_on = [module.apim_policies]
}

# --- APIM Products + demo subscription (optional) ---
#
# Creates an "ai-gateway" product that bundles the LLM APIs from apim-policies,
# exposes it to the Developers group so signed-in portal users see it, and
# pre-bakes a demo subscription whose primary key is returned as a (sensitive)
# Terraform output.

module "apim_products" {
  source = "../../modules/apim-products"

  enable_apim_products = var.enable_apim && var.enable_apim_products
  api_management_name  = module.apim.name
  resource_group_name  = azurerm_resource_group.this.name

  products = [
    {
      name           = "ai-gateway"
      display_name   = "AI Gateway"
      description    = "Unified access to all LLM APIs (Azure OpenAI flavour, OpenAI v1 flavour, Azure AI Inference, and the wildcard unified endpoint) routed across multi-region Foundry backends."
      allowed_groups = ["developers", "guests"]
      api_names = [
        "azure-openai-api",
        "universal-llm-api",
        "ai-model-inference-api",
        "unified-ai-api",
      ]
      subscriptions = [
        { display_name = "demo-key" },
      ]
    },
  ]

  depends_on = [module.apim_policies]
}

# Make the apim-policies-created unified-ai-product visible to signed-in users too.
resource "azurerm_api_management_product_group" "unified_ai_developers" {
  count = var.enable_apim && var.enable_apim_products ? 1 : 0

  resource_group_name = azurerm_resource_group.this.name
  api_management_name = module.apim.name
  product_id          = "unified-ai-product"
  group_name          = "developers"

  depends_on = [module.apim_policies]
}

# --- APIM Developer Portal (optional) ---

module "developer_portal" {
  source = "../../modules/apim-developer-portal"

  enable_developer_portal = var.enable_apim && var.enable_developer_portal
  api_management_id       = module.apim.id
  api_management_name     = module.apim.name
  resource_group_name     = azurerm_resource_group.this.name

  require_signin          = true
  enable_signup           = true
  entra_identity_provider = var.developer_portal_entra

  depends_on = [module.apim_policies]
}

module "litellm" {
  source = "../../modules/litellm"

  enable_litellm             = var.enable_litellm
  resource_group_name        = azurerm_resource_group.this.name
  location                   = var.location
  name_prefix                = local.name_prefix
  enable_private_networking  = var.enable_private_networking
  subnet_id                  = try(module.networking.subnet_ids["litellm"], null)
  dns_zone_id                = try(module.networking.dns_zone_ids["litellm"], null)
  foundry_endpoint           = module.foundry[local.primary_region].ai_services_endpoint
  log_analytics_workspace_id = module.monitoring.log_analytics_workspace_id
  tags                       = local.tags
}

# Grant LiteLLM's managed identity access to the primary AI Services
resource "azurerm_role_assignment" "litellm_cognitive" {
  count = var.enable_litellm ? 1 : 0

  scope                            = module.foundry[local.primary_region].ai_services_id
  role_definition_name             = "Cognitive Services OpenAI User"
  principal_id                     = module.litellm.principal_id
  skip_service_principal_aad_check = true
}

# --- OpenClaw (optional, requires LiteLLM) ---

module "openclaw" {
  source = "../../modules/openclaw"

  enable_openclaw              = var.enable_openclaw
  resource_group_name          = azurerm_resource_group.this.name
  location                     = var.location
  name_prefix                  = local.name_prefix
  enable_private_networking    = var.enable_private_networking
  create_own_environment       = !var.enable_litellm
  container_app_environment_id = var.enable_litellm ? module.litellm.environment_id : null
  litellm_endpoint             = var.enable_litellm ? "https://${module.litellm.endpoint_url}" : ""
  litellm_api_key              = module.litellm.master_key
  extra_secrets                = var.openclaw_extra_secrets
  extra_env                    = var.openclaw_extra_env
  tags                         = local.tags
}

# --- Dashboard ---

module "dashboard" {
  source = "../../modules/dashboard"

  resource_group_name          = azurerm_resource_group.this.name
  location                     = var.location
  name_prefix                  = local.name_prefix
  subscription_id              = data.azurerm_client_config.current.subscription_id
  log_analytics_workspace_id   = module.monitoring.log_analytics_workspace_id
  log_analytics_workspace_name = module.monitoring.log_analytics_workspace_name
  litellm_container_app_name   = "${local.name_prefix}-litellm"
  openclaw_container_app_name  = "${local.name_prefix}-openclaw"
  ai_services_resource_id      = module.foundry[local.primary_region].ai_services_id
  search_service_resource_id   = module.search.search_service_id
  storage_account_resource_id  = module.storage.storage_account_id
  redis_cache_resource_id      = module.redis.redis_cache_id
  tags                         = local.tags
}
