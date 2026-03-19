locals {
  tags = var.tags

  # Helper for KQL part definition
  kql_part = {
    type = "Extension/Microsoft_OperationsManagementSuite_Workspace/PartType/LogsDashboardPart"
  }

  dashboard_properties = templatefile("${path.module}/dashboard.tftpl.json", {
    name_prefix           = var.name_prefix
    workspace_resource_id = var.log_analytics_workspace_id
    workspace_name        = var.log_analytics_workspace_name
    resource_group        = var.resource_group_name
    subscription_id       = var.subscription_id
    litellm_app_name      = var.litellm_container_app_name
    openclaw_app_name     = var.openclaw_container_app_name
    ai_services_id        = var.ai_services_resource_id
    search_id             = var.search_service_resource_id
    storage_id            = var.storage_account_resource_id
  })
}

resource "azurerm_portal_dashboard" "this" {
  name                = "${var.name_prefix}-dashboard"
  resource_group_name = var.resource_group_name
  location            = var.location
  tags                = local.tags

  dashboard_properties = local.dashboard_properties
}
