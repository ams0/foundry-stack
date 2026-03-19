locals {
  tags = var.tags
}

data "azurerm_client_config" "current" {}

resource "azurerm_key_vault" "this" {
  name                = "${var.name_prefix}-kv"
  location            = var.location
  resource_group_name = var.resource_group_name
  tenant_id           = data.azurerm_client_config.current.tenant_id
  sku_name            = "standard"

  rbac_authorization_enabled    = true
  purge_protection_enabled      = true
  soft_delete_retention_days    = var.soft_delete_retention_days
  public_network_access_enabled = !var.enable_private_networking

  tags = local.tags
}
