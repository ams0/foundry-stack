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

  # Sweden Central, base infra only — token/API usage not included.
  estimated_monthly_cost = (
    75.14 + # AI Search (basic)
    5.00 +  # Storage Account
    3.00 +  # Key Vault
    7.50 +  # Log Analytics
    32.00 + # LiteLLM Container App
    64.00   # OpenClaw Container App
  )
}

resource "azurerm_resource_group" "this" {
  name     = "${local.name_prefix}-rg"
  location = var.location
  tags     = local.tags
}

# --- Foundation: networking + observability ---

module "networking" {
  source = "../../modules/networking"

  resource_group_name       = azurerm_resource_group.this.name
  location                  = var.location
  name_prefix               = local.name_prefix
  enable_private_networking = var.enable_private_networking
  enable_litellm            = true
  tags                      = local.tags
}

module "monitoring" {
  source = "../../modules/monitoring"

  resource_group_name = azurerm_resource_group.this.name
  location            = var.location
  name_prefix         = local.name_prefix
  tags                = local.tags

  resource_ids = {
    storage  = module.storage.storage_account_id
    search   = module.search.search_service_id
    keyvault = module.keyvault.key_vault_id
  }
}

# --- Data layer (required by Foundry) ---

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
  sku                       = "basic"
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

# --- AI layer ---

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
  storage_account_id      = module.storage.storage_account_id
  key_vault_id            = module.keyvault.key_vault_id
  application_insights_id = module.monitoring.application_insights_id
  allowed_ips             = var.allowed_ips
  tags                    = local.tags
}

module "rbac" {
  source = "../../modules/rbac"

  foundry_hub_principal_id = module.foundry.hub_principal_id
  ai_services_principal_id = module.foundry.ai_services_principal_id
  storage_account_id       = module.storage.storage_account_id
  search_service_id        = module.search.search_service_id
  key_vault_id             = module.keyvault.key_vault_id
}

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

# --- LiteLLM (Foundry proxy, prerequisite for OpenClaw) ---

module "litellm" {
  source = "../../modules/litellm"

  enable_litellm             = true
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
  scope                            = module.foundry.ai_services_id
  role_definition_name             = "Cognitive Services OpenAI User"
  principal_id                     = module.litellm.principal_id
  skip_service_principal_aad_check = true
}

# --- OpenClaw (the focus of this example) ---

module "openclaw" {
  source = "../../modules/openclaw"

  enable_openclaw              = true
  resource_group_name          = azurerm_resource_group.this.name
  location                     = var.location
  name_prefix                  = local.name_prefix
  enable_private_networking    = var.enable_private_networking
  create_own_environment       = false
  container_app_environment_id = module.litellm.environment_id
  litellm_endpoint             = "https://${module.litellm.endpoint_url}"
  litellm_api_key              = module.litellm.master_key
  extra_secrets                = var.openclaw_extra_secrets
  extra_env                    = var.openclaw_extra_env
  tags                         = local.tags
}
