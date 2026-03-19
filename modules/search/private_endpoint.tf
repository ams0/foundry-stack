resource "azurerm_private_endpoint" "this" {
  count = var.enable_private_networking ? 1 : 0

  name                = "${var.name_prefix}-pe-search"
  location            = var.location
  resource_group_name = var.resource_group_name
  subnet_id           = var.subnet_id
  tags                = local.tags

  private_service_connection {
    name                           = "${var.name_prefix}-psc-search"
    private_connection_resource_id = azurerm_search_service.this.id
    subresource_names              = ["searchService"]
    is_manual_connection           = false
  }

  private_dns_zone_group {
    name                 = "search-dns"
    private_dns_zone_ids = [var.dns_zone_id]
  }
}
