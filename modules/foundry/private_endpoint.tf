resource "azurerm_private_endpoint" "ai_services" {
  count = var.enable_private_networking ? 1 : 0

  name                = "${var.name_prefix}-pe-aiservices"
  location            = var.location
  resource_group_name = var.resource_group_name
  subnet_id           = var.subnet_id
  tags                = local.tags

  private_service_connection {
    name                           = "${var.name_prefix}-psc-aiservices"
    private_connection_resource_id = azapi_resource.ai_services.id
    subresource_names              = ["account"]
    is_manual_connection           = false
  }

  private_dns_zone_group {
    name                 = "aiservices-dns"
    private_dns_zone_ids = [var.dns_zone_ids["cognitiveservices"]]
  }
}

resource "azurerm_private_endpoint" "hub" {
  count = var.create_hub && var.enable_private_networking ? 1 : 0

  name                = "${var.name_prefix}-pe-hub"
  location            = var.location
  resource_group_name = var.resource_group_name
  subnet_id           = var.subnet_id
  tags                = local.tags

  private_service_connection {
    name                           = "${var.name_prefix}-psc-hub"
    private_connection_resource_id = azurerm_ai_foundry.this[0].id
    subresource_names              = ["amlworkspace"]
    is_manual_connection           = false
  }

  private_dns_zone_group {
    name = "hub-dns"
    private_dns_zone_ids = [
      var.dns_zone_ids["foundry_api"],
      var.dns_zone_ids["foundry_notebooks"],
    ]
  }
}
