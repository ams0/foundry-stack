data "azurerm_client_config" "current" {}

locals {
  tags             = var.tags
  app_name         = "${var.name_prefix}-usage-la"
  plan_name        = "${var.name_prefix}-usage-la-plan"
  suffix           = var.enable_logic_app ? random_string.suffix[0].result : "0000"
  storage_name_raw = lower(replace("${var.name_prefix}lausa${local.suffix}", "/[^a-z0-9]/", ""))
  storage_name     = substr(local.storage_name_raw, 0, 24)
  workflows_path   = "${path.module}/workflows"
}

resource "random_string" "suffix" {
  count = var.enable_logic_app ? 1 : 0

  length  = 4
  special = false
  upper   = false
  numeric = true
}

# --- Runtime storage account ---

resource "azurerm_storage_account" "runtime" {
  count = var.enable_logic_app ? 1 : 0

  name                          = local.storage_name
  resource_group_name           = var.resource_group_name
  location                      = var.location
  account_tier                  = "Standard"
  account_replication_type      = "LRS"
  account_kind                  = "StorageV2"
  min_tls_version               = "TLS1_2"
  public_network_access_enabled = !var.enable_private_networking
  shared_access_key_enabled     = true # Logic Apps Standard requires SA key auth on the runtime storage

  tags = local.tags
}

resource "azurerm_storage_container" "packages" {
  count = var.enable_logic_app ? 1 : 0

  name                  = "packages"
  storage_account_id    = azurerm_storage_account.runtime[0].id
  container_access_type = "private"
}

# --- Zip the workflows folder ---

data "archive_file" "workflows" {
  count = var.enable_logic_app ? 1 : 0

  type        = "zip"
  source_dir  = local.workflows_path
  output_path = "${path.module}/.terraform/tmp/workflows-${random_string.suffix[0].result}.zip"
}

resource "azurerm_storage_blob" "workflows" {
  count = var.enable_logic_app ? 1 : 0

  name                   = "workflows-${data.archive_file.workflows[0].output_md5}.zip"
  storage_account_name   = azurerm_storage_account.runtime[0].name
  storage_container_name = azurerm_storage_container.packages[0].name
  type                   = "Block"
  source                 = data.archive_file.workflows[0].output_path
  content_md5            = data.archive_file.workflows[0].output_md5
}

data "azurerm_storage_account_blob_container_sas" "workflows" {
  count = var.enable_logic_app ? 1 : 0

  connection_string = azurerm_storage_account.runtime[0].primary_connection_string
  container_name    = azurerm_storage_container.packages[0].name
  https_only        = true

  start  = "2026-01-01"
  expiry = "2036-01-01"

  permissions {
    read   = true
    add    = false
    create = false
    write  = false
    delete = false
    list   = false
  }
}

# --- App Service plan (workflowapp kind on Windows) ---

resource "azurerm_service_plan" "this" {
  count = var.enable_logic_app ? 1 : 0

  name                = local.plan_name
  resource_group_name = var.resource_group_name
  location            = var.location
  os_type             = "Windows"
  sku_name            = var.sku_name

  tags = local.tags
}

# --- Logic App Standard ---

resource "azurerm_logic_app_standard" "this" {
  count = var.enable_logic_app ? 1 : 0

  name                       = local.app_name
  resource_group_name        = var.resource_group_name
  location                   = var.location
  app_service_plan_id        = azurerm_service_plan.this[0].id
  storage_account_name       = azurerm_storage_account.runtime[0].name
  storage_account_access_key = azurerm_storage_account.runtime[0].primary_access_key

  version = "~4"

  identity {
    type = "SystemAssigned"
  }

  site_config {
    use_32_bit_worker_process = false
    vnet_route_all_enabled    = var.enable_private_networking && var.subnet_id != null
  }

  app_settings = {
    "FUNCTIONS_WORKER_RUNTIME"     = "node"
    "WEBSITE_NODE_DEFAULT_VERSION" = "~20"

    "APPLICATIONINSIGHTS_CONNECTION_STRING" = var.application_insights_connection_string

    # Cosmos (MI auth)
    "AzureCosmosDB_accountEndpoint" = var.cosmos_account_endpoint
    "CosmosDBDatabase"              = var.cosmos_database_name
    "CosmosDBContainerUsage"        = var.cosmos_container_usage
    "CosmosDBContainerPII"          = var.cosmos_container_pii
    "CosmosDBContainerLLMUsage"     = var.cosmos_container_llm_usage
    "CosmosDBContainerConfig"       = var.cosmos_container_config

    # Event Hub (MI auth)
    "eventHub_fullyQualifiedNamespace" = var.event_hub_namespace_fqdn
    "eventHub_name"                    = var.event_hub_usage_name
    "eventHub_pii_name"                = var.event_hub_pii_name

    # Azure Monitor logs (used by scheduled workflows querying App Insights)
    "AppInsights_Name"                = var.application_insights_name
    "AppInsights_ResourceGroup"       = var.application_insights_resource_group
    "AppInsights_SubscriptionId"      = var.application_insights_subscription_id
    "AzureMonitor_Api_Id"             = "/subscriptions/${var.application_insights_subscription_id}/providers/Microsoft.Web/locations/${var.location}/managedApis/azuremonitorlogs"
    "AzureMonitor_Resource_Id"        = "/subscriptions/${var.application_insights_subscription_id}/resourceGroups/${var.application_insights_resource_group}/providers/Microsoft.Web/connections/azuremonitorlogs"
    "AzureMonitor_ConnectRuntime_Url" = ""

    # Code deploy
    "WEBSITE_RUN_FROM_PACKAGE" = "${azurerm_storage_account.runtime[0].primary_blob_endpoint}${azurerm_storage_container.packages[0].name}/${azurerm_storage_blob.workflows[0].name}${data.azurerm_storage_account_blob_container_sas.workflows[0].sas}"
  }

  tags = local.tags
}

# --- Optional diagnostics ---

resource "azurerm_monitor_diagnostic_setting" "this" {
  count = var.enable_logic_app && var.enable_diagnostics ? 1 : 0

  name                       = "${local.app_name}-diag"
  target_resource_id         = azurerm_logic_app_standard.this[0].id
  log_analytics_workspace_id = var.log_analytics_workspace_id

  enabled_log {
    category_group = "allLogs"
  }

  enabled_metric {
    category = "AllMetrics"
  }
}
