locals {
  tags = var.tags

  is_serverless = var.capacity_mode == "serverless"

  # Flatten databases + containers into a single map for for_each
  containers = merge([
    for db_name, containers in var.databases : {
      for c in containers : "${db_name}/${c.name}" => {
        database_name       = db_name
        container_name      = c.name
        partition_key_paths = c.partition_key_paths
      }
    }
  ]...)
}

resource "azurerm_cosmosdb_account" "this" {
  count = var.enable_cosmosdb ? 1 : 0

  name                          = "${var.name_prefix}-cosmos"
  location                      = var.location
  resource_group_name           = var.resource_group_name
  offer_type                    = "Standard"
  kind                          = "GlobalDocumentDB"
  public_network_access_enabled = !var.enable_private_networking
  minimal_tls_version           = "Tls12"

  dynamic "capabilities" {
    for_each = local.is_serverless ? [1] : []
    content {
      name = "EnableServerless"
    }
  }

  consistency_policy {
    consistency_level = "Session"
  }

  geo_location {
    location          = var.location
    failover_priority = 0
  }

  tags = local.tags
}

resource "azurerm_cosmosdb_sql_database" "this" {
  for_each = var.enable_cosmosdb ? var.databases : {}

  name                = each.key
  resource_group_name = var.resource_group_name
  account_name        = azurerm_cosmosdb_account.this[0].name

  dynamic "autoscale_settings" {
    for_each = local.is_serverless ? [] : [1]
    content {
      max_throughput = var.provisioned_throughput
    }
  }
}

resource "azurerm_cosmosdb_sql_container" "this" {
  for_each = var.enable_cosmosdb ? local.containers : {}

  name                = each.value.container_name
  resource_group_name = var.resource_group_name
  account_name        = azurerm_cosmosdb_account.this[0].name
  database_name       = azurerm_cosmosdb_sql_database.this[each.value.database_name].name
  partition_key_paths = each.value.partition_key_paths
}
