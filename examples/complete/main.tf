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

  # Estimated monthly costs (USD) for Sweden Central region.
  # Base infrastructure only — API/token usage costs are not included.
  estimated_costs = {
    ai_search             = var.search_sku == "basic" ? 75.14 : 249.46 # basic ~$75, standard ~$250
    storage_account       = 5.00                                       # Standard LRS, minimal usage
    key_vault             = 3.00                                       # Standard, ~10K operations/month
    log_analytics         = 7.50                                       # ~2.76/GB, estimated 2-3 GB/month
    application_insights  = 0.00                                       # Included with Log Analytics workspace
    ai_foundry_hub        = 0.00                                       # No direct cost (management resource)
    ai_services_s0        = 0.00                                       # Pay-per-use, no base cost
    gpt5_deployment       = 0.00                                       # GlobalStandard: pay-per-token only
    redis_standard_c1     = 81.76                                      # Standard C1 (if enabled)
    apim_developer        = 48.36                                      # Developer SKU (if enabled)
    litellm_container_app = 32.00                                      # 0.5 vCPU, 1Gi, 1 replica (if enabled)
    cosmosdb_serverless   = 0.00                                       # Serverless: pay-per-RU only, no base cost
    cosmosdb_provisioned  = 24.00                                      # Provisioned: ~$24/mo at 1000 RU/s autoscale
    openclaw_container    = 64.00                                      # 1 vCPU, 2Gi, 1 replica (if enabled)
    event_hub_standard    = 22.00                                      # Standard 1 TU (if enabled), $0.03/hr
    logic_app_ws1         = 175.00                                     # WS1 plan (1 vCPU, 3.5GB) if enabled
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
    (var.enable_openclaw ? local.estimated_costs["openclaw_container"] : 0) +
    (var.enable_event_hub ? local.estimated_costs["event_hub_standard"] : 0) +
    (var.enable_logic_app ? local.estimated_costs["logic_app_ws1"] : 0)
  )

  monthly_cost_total = local.monthly_cost_base + local.monthly_cost_optional
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
  enable_event_hub          = var.enable_event_hub
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

  create_logic_app_containers = var.enable_cosmosdb && var.enable_logic_app
  tags                        = local.tags
}

module "event_hub" {
  source = "../../modules/event-hub"

  enable_event_hub           = var.enable_event_hub
  resource_group_name        = azurerm_resource_group.this.name
  location                   = var.location
  name_prefix                = local.name_prefix
  enable_private_networking  = var.enable_private_networking
  subnet_id                  = try(module.networking.subnet_ids["event_hub"], null)
  dns_zone_id                = try(module.networking.dns_zone_ids["event_hub"], null)
  allowed_ips                = var.allowed_ips
  log_analytics_workspace_id = module.monitoring.log_analytics_workspace_id
  tags                       = local.tags
}

# Grant APIM identity Send rights on the Event Hub namespace (APIM EH logger uses MI auth).
resource "azurerm_role_assignment" "apim_eventhub_sender" {
  count = var.enable_apim && var.enable_apim_policies && var.enable_event_hub ? 1 : 0

  scope                = module.event_hub.namespace_id
  role_definition_name = "Azure Event Hubs Data Sender"
  principal_id         = module.apim.principal_id
}

# --- AI Layer ---

module "foundry" {
  source = "../../modules/foundry"

  resource_group_name       = azurerm_resource_group.this.name
  location                  = var.location
  name_prefix               = local.name_prefix
  enable_private_networking = var.enable_private_networking
  subnet_id                 = try(module.networking.subnet_ids["foundry"], null)
  dns_zone_ids = {
    cognitiveservices = try(module.networking.dns_zone_ids["cognitiveservices"], "")
    foundry_api       = try(module.networking.dns_zone_ids["foundry_api"], "")
    foundry_notebooks = try(module.networking.dns_zone_ids["foundry_notebooks"], "")
  }
  storage_account_id                    = module.storage.storage_account_id
  key_vault_id                          = module.keyvault.key_vault_id
  application_insights_id               = module.monitoring.application_insights_id
  allowed_ips                           = var.allowed_ips
  policy_exemption_policy_assignment_id = var.policy_exemption_policy_assignment_id
  enable_redis                          = var.enable_redis
  redis_cache_hostname                  = module.redis.hostname
  redis_cache_primary_key               = module.redis.primary_access_key
  tags                                  = local.tags
}

module "rbac" {
  source = "../../modules/rbac"

  foundry_hub_principal_id = module.foundry.hub_principal_id
  ai_services_principal_id = module.foundry.ai_services_principal_id
  storage_account_id       = module.storage.storage_account_id
  search_service_id        = module.search.search_service_id
  key_vault_id             = module.keyvault.key_vault_id
  redis_cache_id           = module.redis.redis_cache_id
  enable_redis             = var.enable_redis
}

# --- Diagnostic settings for resources created after monitoring ---

resource "azurerm_monitor_diagnostic_setting" "foundry" {
  name                       = "foundry-diag"
  target_resource_id         = module.foundry.ai_services_id
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
  foundry_endpoint          = module.foundry.ai_services_endpoint
  tags                      = local.tags
}

# --- APIM policy stack (citadel-v1 parity) ---

module "apim_policies" {
  source = "../../modules/apim-policies"

  enable_apim_policies = var.enable_apim && var.enable_apim_policies

  api_management_id   = module.apim.id
  api_management_name = module.apim.name
  resource_group_name = azurerm_resource_group.this.name
  apim_principal_id   = module.apim.principal_id

  application_insights_id                = module.monitoring.application_insights_id
  application_insights_connection_string = module.monitoring.application_insights_connection_string
  log_analytics_workspace_id             = module.monitoring.log_analytics_workspace_id

  enable_event_hub_logger       = var.enable_event_hub
  enable_event_hub_pii_logger   = var.enable_event_hub
  event_hub_logger_name         = var.enable_event_hub ? module.event_hub.usage_hub_name : ""
  event_hub_logger_endpoint     = var.enable_event_hub ? module.event_hub.namespace_endpoint : ""
  event_hub_pii_logger_name     = var.enable_event_hub ? module.event_hub.pii_hub_name : ""
  event_hub_pii_logger_endpoint = var.enable_event_hub ? module.event_hub.namespace_endpoint : ""

  llm_backends = var.enable_apim_policies ? [
    {
      backend_id   = "foundry-primary"
      backend_type = "ai-foundry"
      endpoint     = module.foundry.ai_services_endpoint
      supported_models = [
        for d in var.apim_policies_foundry_models : {
          name          = d.name
          model_version = d.model_version
          model_format  = d.model_format
        }
      ]
    }
  ] : []

  enable_azure_openai_api      = var.apim_policies_enable_azure_openai_api
  enable_universal_llm_api     = var.apim_policies_enable_universal_llm_api
  enable_unified_ai_api        = var.apim_policies_enable_unified_ai_api
  enable_ai_model_inference    = var.apim_policies_enable_ai_model_inference
  enable_openai_realtime       = var.apim_policies_enable_openai_realtime
  enable_document_intelligence = var.apim_policies_enable_document_intelligence
  enable_ai_search             = var.apim_policies_enable_ai_search
  enable_translator            = var.apim_policies_enable_translator
  enable_language              = var.apim_policies_enable_language
  enable_speech                = var.apim_policies_enable_speech
  enable_pii_anonymization     = var.apim_policies_enable_pii_anonymization
  enable_mcp_samples           = var.apim_policies_enable_mcp_samples

  entra_auth      = var.apim_policies_entra_auth
  entra_tenant_id = var.apim_policies_entra_tenant_id
  entra_client_id = var.apim_policies_entra_client_id
  entra_audience  = var.apim_policies_entra_audience
  enable_jwt_auth = var.apim_policies_enable_jwt_auth
}

# Grant APIM's identity Cognitive Services OpenAI User on Foundry (backend MI auth).
resource "azurerm_role_assignment" "apim_cognitive" {
  count = var.enable_apim && var.enable_apim_policies ? 1 : 0

  scope                = module.foundry.ai_services_id
  role_definition_name = "Cognitive Services OpenAI User"
  principal_id         = module.apim.principal_id
}

# --- Logic App usage-ingestion (consumes EH → writes to Cosmos) ---

module "logic_app" {
  source = "../../modules/logic-app"

  enable_logic_app    = var.enable_logic_app
  resource_group_name = azurerm_resource_group.this.name
  location            = var.location
  name_prefix         = local.name_prefix

  event_hub_namespace_fqdn = module.event_hub.namespace_fqdn
  event_hub_usage_name     = module.event_hub.usage_hub_name
  event_hub_pii_name       = module.event_hub.pii_hub_name

  cosmos_account_endpoint    = module.cosmosdb.endpoint
  cosmos_database_name       = try(module.cosmosdb.logic_app_database, "ai-usage")
  cosmos_container_usage     = try(module.cosmosdb.logic_app_container_names["usage"], "usage")
  cosmos_container_pii       = try(module.cosmosdb.logic_app_container_names["pii_usage"], "pii-usage")
  cosmos_container_llm_usage = try(module.cosmosdb.logic_app_container_names["llm_usage"], "llm-usage")
  cosmos_container_config    = try(module.cosmosdb.logic_app_container_names["config"], "config")

  application_insights_name              = "${local.name_prefix}-appinsights"
  application_insights_resource_group    = azurerm_resource_group.this.name
  application_insights_subscription_id   = data.azurerm_client_config.current.subscription_id
  application_insights_connection_string = module.monitoring.application_insights_connection_string

  enable_private_networking  = var.enable_private_networking
  log_analytics_workspace_id = module.monitoring.log_analytics_workspace_id

  tags = local.tags
}

# --- Logic App role assignments ---

# 1. Receive events from both hubs.
resource "azurerm_role_assignment" "logic_app_eh_receiver" {
  count = var.enable_logic_app && var.enable_event_hub ? 1 : 0

  scope                = module.event_hub.namespace_id
  role_definition_name = "Azure Event Hubs Data Receiver"
  principal_id         = module.logic_app.principal_id
}

# 2. Write to Cosmos via SQL data-plane RBAC (Cosmos DB Built-in Data Contributor).
resource "azurerm_cosmosdb_sql_role_assignment" "logic_app" {
  count = var.enable_logic_app && var.enable_cosmosdb ? 1 : 0

  resource_group_name = azurerm_resource_group.this.name
  account_name        = module.cosmosdb.account_name
  scope               = module.cosmosdb.account_id
  # 00000000-0000-0000-0000-000000000002 = Cosmos DB Built-in Data Contributor
  role_definition_id = "${module.cosmosdb.account_id}/sqlRoleDefinitions/00000000-0000-0000-0000-000000000002"
  principal_id       = module.logic_app.principal_id
}

# 3. Read App Insights for scheduled workflows.
resource "azurerm_role_assignment" "logic_app_appinsights_reader" {
  count = var.enable_logic_app ? 1 : 0

  scope                = module.monitoring.application_insights_id
  role_definition_name = "Monitoring Reader"
  principal_id         = module.logic_app.principal_id
}

# 4. Read Log Analytics workspace (App Insights queries hit the workspace).
resource "azurerm_role_assignment" "logic_app_la_reader" {
  count = var.enable_logic_app ? 1 : 0

  scope                = module.monitoring.log_analytics_workspace_id
  role_definition_name = "Log Analytics Reader"
  principal_id         = module.logic_app.principal_id
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
  foundry_endpoint           = module.foundry.ai_services_endpoint
  log_analytics_workspace_id = module.monitoring.log_analytics_workspace_id
  tags                       = local.tags
}

# Grant LiteLLM's managed identity access to AI Services
resource "azurerm_role_assignment" "litellm_cognitive" {
  count = var.enable_litellm ? 1 : 0

  scope                            = module.foundry.ai_services_id
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
  ai_services_resource_id      = module.foundry.ai_services_id
  search_service_resource_id   = module.search.search_service_id
  storage_account_resource_id  = module.storage.storage_account_id
  redis_cache_resource_id      = module.redis.redis_cache_id
  tags                         = local.tags
}
