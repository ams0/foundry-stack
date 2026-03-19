locals {
  tags = var.tags
}

resource "azurerm_log_analytics_workspace" "this" {
  name                = "${var.name_prefix}-law"
  location            = var.location
  resource_group_name = var.resource_group_name
  sku                 = "PerGB2018"
  retention_in_days   = var.retention_days
  tags                = local.tags
}

resource "azurerm_application_insights" "this" {
  name                = "${var.name_prefix}-appi"
  location            = var.location
  resource_group_name = var.resource_group_name
  workspace_id        = azurerm_log_analytics_workspace.this.id
  application_type    = "web"
  tags                = local.tags
}

# Resources that don't support the allLogs category group (e.g. Storage Accounts
# expose logs on sub-resources like blob/queue/table, not on the account itself).
locals {
  metrics_only_resources = toset(["storage"])
  log_resource_ids       = { for k, v in var.resource_ids : k => v if !contains(local.metrics_only_resources, k) }
  metric_resource_ids    = { for k, v in var.resource_ids : k => v if contains(local.metrics_only_resources, k) }
}

resource "azurerm_monitor_diagnostic_setting" "logs_and_metrics" {
  for_each = local.log_resource_ids

  name                       = "${each.key}-diag"
  target_resource_id         = each.value
  log_analytics_workspace_id = azurerm_log_analytics_workspace.this.id

  enabled_log {
    category_group = "allLogs"
  }

  enabled_metric {
    category = "AllMetrics"
  }
}

resource "azurerm_monitor_diagnostic_setting" "metrics_only" {
  for_each = local.metric_resource_ids

  name                       = "${each.key}-diag"
  target_resource_id         = each.value
  log_analytics_workspace_id = azurerm_log_analytics_workspace.this.id

  # Storage Accounts don't support AllMetrics — use specific categories
  enabled_metric {
    category = "Transaction"
  }

  enabled_metric {
    category = "Capacity"
  }
}

resource "azurerm_monitor_action_group" "this" {
  count = var.alert_email != null ? 1 : 0

  name                = "${var.name_prefix}-ag"
  resource_group_name = var.resource_group_name
  short_name          = substr(var.name_prefix, 0, 12)
  tags                = local.tags

  email_receiver {
    name          = "admin"
    email_address = var.alert_email
  }
}

locals {
  action_group_id = var.alert_email != null ? azurerm_monitor_action_group.this[0].id : null

  storage_alerts = contains(keys(var.resource_ids), "storage") ? {
    storage_availability = {
      resource_id      = var.resource_ids["storage"]
      metric_namespace = "Microsoft.Storage/storageAccounts"
      metric_name      = "Availability"
      operator         = "LessThan"
      threshold        = 99.9
      aggregation      = "Average"
      description      = "Storage availability below 99.9%"
    }
    storage_latency = {
      resource_id      = var.resource_ids["storage"]
      metric_namespace = "Microsoft.Storage/storageAccounts"
      metric_name      = "SuccessE2ELatency"
      operator         = "GreaterThan"
      threshold        = 1000
      aggregation      = "Average"
      description      = "Storage E2E latency above 1000ms"
    }
  } : {}

  search_alerts = contains(keys(var.resource_ids), "search") ? {
    search_throttled = {
      resource_id      = var.resource_ids["search"]
      metric_namespace = "Microsoft.Search/searchServices"
      metric_name      = "ThrottledSearchQueriesPercentage"
      operator         = "GreaterThan"
      threshold        = 5
      aggregation      = "Average"
      description      = "Search throttled queries above 5%"
    }
    search_latency = {
      resource_id      = var.resource_ids["search"]
      metric_namespace = "Microsoft.Search/searchServices"
      metric_name      = "SearchLatency"
      operator         = "GreaterThan"
      threshold        = 1000
      aggregation      = "Average"
      description      = "Search latency above 1000ms"
    }
  } : {}

  keyvault_alerts = contains(keys(var.resource_ids), "keyvault") ? {
    keyvault_availability = {
      resource_id      = var.resource_ids["keyvault"]
      metric_namespace = "Microsoft.KeyVault/vaults"
      metric_name      = "Availability"
      operator         = "LessThan"
      threshold        = 99.9
      aggregation      = "Average"
      description      = "Key Vault availability below 99.9%"
    }
  } : {}

  redis_alerts = var.enable_redis && contains(keys(var.resource_ids), "redis") ? {
    redis_memory = {
      resource_id      = var.resource_ids["redis"]
      metric_namespace = "Microsoft.Cache/redis"
      metric_name      = "usedmemorypercentage"
      operator         = "GreaterThan"
      threshold        = 80
      aggregation      = "Average"
      description      = "Redis memory usage above 80%"
    }
    redis_cache_misses = {
      resource_id      = var.resource_ids["redis"]
      metric_namespace = "Microsoft.Cache/redis"
      metric_name      = "cachemissrate"
      operator         = "GreaterThan"
      threshold        = 50
      aggregation      = "Average"
      description      = "Redis cache miss rate above 50%"
    }
  } : {}

  foundry_alerts = contains(keys(var.resource_ids), "foundry") ? {
    foundry_failed_requests = {
      resource_id      = var.resource_ids["foundry"]
      metric_namespace = "Microsoft.CognitiveServices/accounts"
      metric_name      = "ClientErrors"
      operator         = "GreaterThan"
      threshold        = 5
      aggregation      = "Total"
      description      = "Foundry AI Services client errors above 5%"
    }
  } : {}

  all_alerts = var.alert_email != null ? merge(
    local.storage_alerts,
    local.search_alerts,
    local.keyvault_alerts,
    local.redis_alerts,
    local.foundry_alerts,
  ) : {}
}

resource "azurerm_monitor_metric_alert" "this" {
  for_each = local.all_alerts

  name                = "${var.name_prefix}-alert-${each.key}"
  resource_group_name = var.resource_group_name
  scopes              = [each.value.resource_id]
  description         = each.value.description
  severity            = 2
  frequency           = "PT5M"
  window_size         = "PT15M"
  tags                = local.tags

  criteria {
    metric_namespace = each.value.metric_namespace
    metric_name      = each.value.metric_name
    aggregation      = each.value.aggregation
    operator         = each.value.operator
    threshold        = each.value.threshold
  }

  action {
    action_group_id = local.action_group_id
  }
}
