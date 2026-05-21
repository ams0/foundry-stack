locals {
  tags                = var.tags
  namespace_name      = "${var.name_prefix}-ehns"
  use_auto_inflate    = var.sku == "Standard" && var.auto_inflate_enabled
  public_access_state = var.enable_private_networking ? false : true
  default_action      = var.enable_private_networking ? "Deny" : "Allow"
  effective_ip_rules  = var.enable_private_networking ? [] : var.allowed_ips
}

resource "azurerm_eventhub_namespace" "this" {
  count = var.enable_event_hub ? 1 : 0

  name                = local.namespace_name
  location            = var.location
  resource_group_name = var.resource_group_name
  sku                 = var.sku
  capacity            = var.capacity

  auto_inflate_enabled     = local.use_auto_inflate
  maximum_throughput_units = local.use_auto_inflate ? var.maximum_throughput_units : null

  public_network_access_enabled = local.public_access_state
  local_authentication_enabled  = true

  identity {
    type = "SystemAssigned"
  }

  network_rulesets = [{
    default_action                 = local.default_action
    trusted_service_access_enabled = true
    public_network_access_enabled  = local.public_access_state
    ip_rule = [
      for ip in local.effective_ip_rules : {
        ip_mask = ip
        action  = "Allow"
      }
    ]
    virtual_network_rule = []
  }]

  tags = local.tags
}

resource "azurerm_eventhub" "usage" {
  count = var.enable_event_hub ? 1 : 0

  name              = var.usage_hub_name
  namespace_id      = azurerm_eventhub_namespace.this[0].id
  partition_count   = var.partition_count
  message_retention = var.message_retention
}

resource "azurerm_eventhub" "pii" {
  count = var.enable_event_hub ? 1 : 0

  name              = var.pii_hub_name
  namespace_id      = azurerm_eventhub_namespace.this[0].id
  partition_count   = var.partition_count
  message_retention = var.message_retention
}

resource "azurerm_monitor_diagnostic_setting" "this" {
  count = var.enable_event_hub && var.enable_diagnostics ? 1 : 0

  name                       = "${local.namespace_name}-diag"
  target_resource_id         = azurerm_eventhub_namespace.this[0].id
  log_analytics_workspace_id = var.log_analytics_workspace_id

  enabled_log {
    category_group = "allLogs"
  }

  enabled_metric {
    category = "AllMetrics"
  }
}
