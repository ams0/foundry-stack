locals {
  tags = var.tags
}

resource "azurerm_api_management" "this" {
  count = var.enable_apim ? 1 : 0

  name                = "${var.name_prefix}-apim"
  location            = var.location
  resource_group_name = var.resource_group_name
  publisher_name      = var.publisher_name
  publisher_email     = var.publisher_email
  sku_name            = var.sku_name

  identity {
    type = "SystemAssigned"
  }

  tags = local.tags
}

resource "azurerm_api_management_api" "foundry" {
  count = var.enable_apim ? 1 : 0

  name                = "foundry-api"
  resource_group_name = var.resource_group_name
  api_management_name = azurerm_api_management.this[0].name
  revision            = "1"
  display_name        = "AI Foundry API"
  protocols           = ["https"]
  service_url         = var.foundry_endpoint
}
