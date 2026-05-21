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
