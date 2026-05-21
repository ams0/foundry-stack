# --- Loggers ---

resource "azurerm_api_management_logger" "appinsights" {
  count = var.enable_apim_policies && var.enable_application_insights_logger ? 1 : 0

  name                = "appinsights-logger"
  resource_group_name = var.resource_group_name
  api_management_name = var.api_management_name
  description         = "Application Insights logger for API observability"
  resource_id         = var.application_insights_id

  application_insights {
    connection_string = var.application_insights_connection_string
  }
}

# Azure Monitor logger (Log Analytics destination is configured via the service diagnostic settings).
resource "azapi_resource" "azuremonitor_logger" {
  count = var.enable_apim_policies ? 1 : 0

  type      = "Microsoft.ApiManagement/service/loggers@2024-10-01-preview"
  name      = "azuremonitor"
  parent_id = var.api_management_id

  body = {
    properties = {
      loggerType  = "azureMonitor"
      isBuffered  = false
      description = "Azure Monitor logger for Log Analytics"
    }
  }
}

# Event Hub loggers — only when EH inputs are provided.
resource "azapi_resource" "eventhub_logger" {
  count = var.enable_apim_policies && var.enable_event_hub_logger ? 1 : 0

  type                      = "Microsoft.ApiManagement/service/loggers@2022-08-01"
  name                      = "usage-eventhub-logger"
  parent_id                 = var.api_management_id
  schema_validation_enabled = false

  body = {
    properties = {
      loggerType  = "azureEventHub"
      description = "Event Hub logger for OpenAI usage metrics"
      credentials = {
        name             = var.event_hub_logger_name
        endpointAddress  = replace(var.event_hub_logger_endpoint, "https://", "")
        identityClientId = var.apim_identity_client_id != "" ? var.apim_identity_client_id : "SystemAssigned"
      }
    }
  }
}

resource "azapi_resource" "eventhub_pii_logger" {
  count = var.enable_apim_policies && var.enable_pii_anonymization && var.enable_event_hub_pii_logger ? 1 : 0

  type                      = "Microsoft.ApiManagement/service/loggers@2022-08-01"
  name                      = "pii-usage-eventhub-logger"
  parent_id                 = var.api_management_id
  schema_validation_enabled = false

  body = {
    properties = {
      loggerType  = "azureEventHub"
      description = "Event Hub logger for PII usage metrics and logs"
      credentials = {
        name             = var.event_hub_pii_logger_name
        endpointAddress  = replace(var.event_hub_pii_logger_endpoint, "https://", "")
        identityClientId = var.apim_identity_client_id != "" ? var.apim_identity_client_id : "SystemAssigned"
      }
    }
  }
}

# --- Service-level diagnostics ---

resource "azurerm_api_management_diagnostic" "appinsights" {
  count = var.enable_apim_policies && var.enable_application_insights_logger ? 1 : 0

  identifier               = "applicationinsights"
  resource_group_name      = var.resource_group_name
  api_management_name      = var.api_management_name
  api_management_logger_id = azurerm_api_management_logger.appinsights[0].id

  always_log_errors         = true
  http_correlation_protocol = "W3C"
  log_client_ip             = true
  verbosity                 = "information"
  sampling_percentage       = 100

  frontend_request {
    body_bytes = 0
  }
  frontend_response {
    body_bytes = 0
  }
  backend_request {
    body_bytes = 0
  }
  backend_response {
    body_bytes = 0
  }
}

resource "azurerm_monitor_diagnostic_setting" "apim" {
  count = var.enable_apim_policies && var.enable_diagnostics ? 1 : 0

  name                           = "apim-diag"
  target_resource_id             = var.api_management_id
  log_analytics_workspace_id     = var.log_analytics_workspace_id
  log_analytics_destination_type = "Dedicated"

  enabled_log {
    category_group = "AllLogs"
  }

  enabled_metric {
    category = "AllMetrics"
  }
}
