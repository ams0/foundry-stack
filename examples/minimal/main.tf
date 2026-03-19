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
  estimated_monthly_cost = (
    249.46 + # AI Search Standard (1 replica, 1 partition)
    5.00 +   # Storage Account (Standard LRS, minimal)
    3.00 +   # Key Vault (Standard, ~10K ops/month)
    7.50     # Log Analytics (~2-3 GB/month)
  )          # Total: ~$264.96/month
}

resource "azurerm_resource_group" "this" {
  name     = "${local.name_prefix}-rg"
  location = var.location
  tags     = local.tags
}

module "networking" {
  source = "../../modules/networking"

  resource_group_name       = azurerm_resource_group.this.name
  location                  = var.location
  name_prefix               = local.name_prefix
  enable_private_networking = var.enable_private_networking
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
