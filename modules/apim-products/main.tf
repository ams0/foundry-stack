locals {
  enabled = var.enable_apim_products

  products_map = local.enabled ? { for p in var.products : p.name => p } : {}

  # Cartesian product of (product, api_name) for product↔api wiring.
  product_apis = local.enabled ? {
    for pair in flatten([
      for p in var.products : [
        for api in p.api_names : {
          key     = "${p.name}|${api}"
          product = p.name
          api     = api
        }
      ]
    ]) : pair.key => pair
  } : {}

  # Cartesian product of (product, group) for visibility.
  product_groups = local.enabled ? {
    for pair in flatten([
      for p in var.products : [
        for g in p.allowed_groups : {
          key     = "${p.name}|${g}"
          product = p.name
          group   = g
        }
      ]
    ]) : pair.key => pair
  } : {}

  # Cartesian product of (product, subscription) — each pre-baked sub gets a key.
  subscriptions_flat = local.enabled ? {
    for s in flatten([
      for p in var.products : [
        for sub in p.subscriptions : {
          key             = "${p.name}|${coalesce(sub.subscription_id, replace(lower(sub.display_name), "/[^a-z0-9-]/", "-"))}"
          product         = p.name
          display_name    = sub.display_name
          subscription_id = coalesce(sub.subscription_id, replace(lower(sub.display_name), "/[^a-z0-9-]/", "-"))
        }
      ]
    ]) : s.key => s
  } : {}
}

resource "azurerm_api_management_product" "this" {
  for_each = local.products_map

  product_id            = each.value.name
  api_management_name   = var.api_management_name
  resource_group_name   = var.resource_group_name
  display_name          = each.value.display_name
  description           = each.value.description
  subscription_required = each.value.subscription_required
  approval_required     = each.value.approval_required
  subscriptions_limit   = each.value.subscriptions_limit
  published             = each.value.published
}

resource "azurerm_api_management_product_api" "this" {
  for_each = local.product_apis

  api_management_name = var.api_management_name
  resource_group_name = var.resource_group_name
  product_id          = azurerm_api_management_product.this[each.value.product].product_id
  api_name            = each.value.api
}

resource "azurerm_api_management_product_group" "this" {
  for_each = local.product_groups

  api_management_name = var.api_management_name
  resource_group_name = var.resource_group_name
  product_id          = azurerm_api_management_product.this[each.value.product].product_id
  group_name          = each.value.group
}

resource "azurerm_api_management_subscription" "this" {
  for_each = local.subscriptions_flat

  api_management_name = var.api_management_name
  resource_group_name = var.resource_group_name
  subscription_id     = each.value.subscription_id
  display_name        = each.value.display_name
  product_id          = azurerm_api_management_product.this[each.value.product].id
  state               = "active"
  allow_tracing       = false
}
