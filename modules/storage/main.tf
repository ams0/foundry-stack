locals {
  tags = var.tags

  storage_account_name = replace("${var.name_prefix}storage", "-", "")
}

resource "azurerm_storage_account" "this" {
  name                     = substr(local.storage_account_name, 0, 24)
  resource_group_name      = var.resource_group_name
  location                 = var.location
  account_tier             = var.account_tier
  account_replication_type = var.account_replication_type
  is_hns_enabled           = false
  min_tls_version          = "TLS1_2"

  allow_nested_items_to_be_public = false
  public_network_access_enabled   = !var.enable_private_networking

  identity {
    type = "SystemAssigned"
  }

  tags = local.tags
}

resource "azurerm_storage_container" "this" {
  for_each = toset(var.containers)

  name                  = each.value
  storage_account_id    = azurerm_storage_account.this.id
  container_access_type = "private"
}

resource "azurerm_storage_account_network_rules" "this" {
  count = var.enable_private_networking ? 1 : 0

  storage_account_id = azurerm_storage_account.this.id
  default_action     = "Deny"
  bypass             = ["AzureServices"]
}
