resource "azurerm_private_endpoint" "this" {
  count = var.enable_event_hub && var.enable_private_networking && var.subnet_id != null ? 1 : 0

  name                = "${local.namespace_name}-pe"
  location            = var.location
  resource_group_name = var.resource_group_name
  subnet_id           = var.subnet_id
  tags                = local.tags

  private_service_connection {
    name                           = "${local.namespace_name}-psc"
    private_connection_resource_id = azurerm_eventhub_namespace.this[0].id
    subresource_names              = ["namespace"]
    is_manual_connection           = false
  }

  dynamic "private_dns_zone_group" {
    for_each = var.dns_zone_id != null && var.dns_zone_id != "" ? [1] : []
    content {
      name                 = "default"
      private_dns_zone_ids = [var.dns_zone_id]
    }
  }
}
