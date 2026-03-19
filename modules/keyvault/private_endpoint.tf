resource "azurerm_private_endpoint" "this" {
  count = var.enable_private_networking ? 1 : 0

  name                = "${var.name_prefix}-pe-kv"
  location            = var.location
  resource_group_name = var.resource_group_name
  subnet_id           = var.subnet_id
  tags                = local.tags

  private_service_connection {
    name                           = "${var.name_prefix}-psc-kv"
    private_connection_resource_id = azurerm_key_vault.this.id
    subresource_names              = ["vault"]
    is_manual_connection           = false
  }

  private_dns_zone_group {
    name                 = "kv-dns"
    private_dns_zone_ids = [var.dns_zone_id]
  }
}
