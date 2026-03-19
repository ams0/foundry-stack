locals {
  tags = var.tags

  core_dns_zones = {
    blob              = "privatelink.blob.core.windows.net"
    dfs               = "privatelink.dfs.core.windows.net"
    search            = "privatelink.search.windows.net"
    keyvault          = "privatelink.vaultcore.azure.net"
    cognitiveservices = "privatelink.cognitiveservices.azure.com"
    foundry_api       = "privatelink.api.azureml.ms"
    foundry_notebooks = "privatelink.notebooks.azure.net"
    monitor           = "privatelink.monitor.azure.com"
    oms               = "privatelink.oms.opinsights.azure.com"
    ods               = "privatelink.ods.opinsights.azure.com"
    agentsvc          = "privatelink.agentsvc.azure-automation.net"
  }

  optional_dns_zones = merge(
    var.enable_redis ? { redis = "privatelink.redis.cache.windows.net" } : {},
    var.enable_apim ? { apim = "privatelink.azure-api.net" } : {},
    var.enable_litellm ? { litellm = "privatelink.${var.location}.azurecontainerapps.io" } : {},
    var.enable_cosmosdb ? { cosmosdb = "privatelink.documents.azure.com" } : {},
  )

  all_dns_zones = var.enable_private_networking ? merge(local.core_dns_zones, local.optional_dns_zones) : {}

  core_subnets = {
    foundry  = var.subnet_cidrs["foundry"]
    storage  = var.subnet_cidrs["storage"]
    search   = var.subnet_cidrs["search"]
    keyvault = var.subnet_cidrs["keyvault"]
  }

  optional_subnets = merge(
    var.enable_redis ? { redis = var.subnet_cidrs["redis"] } : {},
    var.enable_apim ? { apim = var.subnet_cidrs["apim"] } : {},
    var.enable_litellm ? { litellm = var.subnet_cidrs["litellm"] } : {},
    var.enable_cosmosdb ? { cosmosdb = var.subnet_cidrs["cosmosdb"] } : {},
  )

  all_subnets = var.enable_private_networking ? merge(local.core_subnets, local.optional_subnets) : {}
}

resource "azurerm_virtual_network" "this" {
  count = var.enable_private_networking ? 1 : 0

  name                = "${var.name_prefix}-vnet"
  location            = var.location
  resource_group_name = var.resource_group_name
  address_space       = var.address_space
  tags                = local.tags
}

resource "azurerm_subnet" "this" {
  for_each = local.all_subnets

  name                 = "${var.name_prefix}-snet-${each.key}"
  resource_group_name  = var.resource_group_name
  virtual_network_name = azurerm_virtual_network.this[0].name
  address_prefixes     = [each.value]
}

resource "azurerm_network_security_group" "this" {
  for_each = local.all_subnets

  name                = "${var.name_prefix}-nsg-${each.key}"
  location            = var.location
  resource_group_name = var.resource_group_name
  tags                = local.tags
}

resource "azurerm_subnet_network_security_group_association" "this" {
  for_each = local.all_subnets

  subnet_id                 = azurerm_subnet.this[each.key].id
  network_security_group_id = azurerm_network_security_group.this[each.key].id
}

resource "azurerm_private_dns_zone" "this" {
  for_each = local.all_dns_zones

  name                = each.value
  resource_group_name = var.resource_group_name
  tags                = local.tags
}

resource "azurerm_private_dns_zone_virtual_network_link" "this" {
  for_each = local.all_dns_zones

  name                  = "${var.name_prefix}-dnslink-${each.key}"
  resource_group_name   = var.resource_group_name
  private_dns_zone_name = azurerm_private_dns_zone.this[each.key].name
  virtual_network_id    = azurerm_virtual_network.this[0].id
  registration_enabled  = false
  tags                  = local.tags
}

resource "azurerm_monitor_private_link_scope" "this" {
  count = var.enable_private_networking ? 1 : 0

  name                = "${var.name_prefix}-ampls"
  resource_group_name = var.resource_group_name
  tags                = local.tags
}
