locals {
  tags = var.tags
}

resource "azurerm_search_service" "this" {
  name                          = "${var.name_prefix}-search"
  resource_group_name           = var.resource_group_name
  location                      = var.location
  sku                           = var.sku
  replica_count                 = var.replica_count
  partition_count               = var.partition_count
  public_network_access_enabled = !var.enable_private_networking
  semantic_search_sku           = "standard"

  identity {
    type = "SystemAssigned"
  }

  tags = local.tags
}
