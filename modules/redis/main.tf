locals {
  tags = var.tags
}

resource "azurerm_redis_cache" "this" {
  count = var.enable_redis ? 1 : 0

  name                          = "${var.name_prefix}-redis"
  location                      = var.location
  resource_group_name           = var.resource_group_name
  capacity                      = var.capacity
  family                        = var.family
  sku_name                      = var.sku_name
  non_ssl_port_enabled          = false
  minimum_tls_version           = "1.2"
  public_network_access_enabled = !var.enable_private_networking

  redis_configuration {}

  tags = local.tags
}
