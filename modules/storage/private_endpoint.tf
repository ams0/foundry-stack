resource "azurerm_private_endpoint" "blob" {
  count = var.enable_private_networking ? 1 : 0

  name                = "${var.name_prefix}-pe-blob"
  location            = var.location
  resource_group_name = var.resource_group_name
  subnet_id           = var.subnet_id
  tags                = local.tags

  private_service_connection {
    name                           = "${var.name_prefix}-psc-blob"
    private_connection_resource_id = azurerm_storage_account.this.id
    subresource_names              = ["blob"]
    is_manual_connection           = false
  }

  private_dns_zone_group {
    name                 = "blob-dns"
    private_dns_zone_ids = [var.dns_zone_ids["blob"]]
  }
}

resource "azurerm_private_endpoint" "dfs" {
  count = var.enable_private_networking ? 1 : 0

  name                = "${var.name_prefix}-pe-dfs"
  location            = var.location
  resource_group_name = var.resource_group_name
  subnet_id           = var.subnet_id
  tags                = local.tags

  private_service_connection {
    name                           = "${var.name_prefix}-psc-dfs"
    private_connection_resource_id = azurerm_storage_account.this.id
    subresource_names              = ["dfs"]
    is_manual_connection           = false
  }

  private_dns_zone_group {
    name                 = "dfs-dns"
    private_dns_zone_ids = [var.dns_zone_ids["dfs"]]
  }
}
