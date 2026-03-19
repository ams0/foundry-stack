resource "random_password" "litellm_master_key" {
  count   = var.enable_litellm && var.master_key == "" ? 1 : 0
  length  = 24
  special = false
}

locals {
  tags = var.tags

  litellm_master_key = var.master_key != "" ? var.master_key : (
    var.enable_litellm ? random_password.litellm_master_key[0].result : ""
  )

  # Build LiteLLM config YAML with model routing via managed identity
  litellm_config = yamlencode({
    model_list = [
      for d in var.model_deployments : {
        model_name = d.model_name
        litellm_params = {
          model       = "azure/${d.deployment_name}"
          api_base    = var.foundry_endpoint
          api_version = var.api_version
        }
      }
    ]
    litellm_settings = {
      enable_azure_ad_token_refresh = true

      # Structured JSON logging for all requests — queryable via KQL
      success_callback = ["log_raw_request_response"]
      failure_callback = ["log_raw_request_response"]
      service_callback = ["prometheus"]

      # Log request/response details to stdout (picked up by Container App logs)
      json_logs                = true
      log_raw_request_response = true
    }

    # Prometheus metrics at /metrics endpoint
    general_settings = {
      enable_prometheus_metrics = true
    }
  })
}

resource "azurerm_container_app_environment" "this" {
  count = var.enable_litellm ? 1 : 0

  name                           = "${var.name_prefix}-cae"
  location                       = var.location
  resource_group_name            = var.resource_group_name
  infrastructure_subnet_id       = var.enable_private_networking ? var.subnet_id : null
  internal_load_balancer_enabled = var.enable_private_networking ? true : null
  log_analytics_workspace_id     = var.log_analytics_workspace_id

  tags = local.tags

  lifecycle {
    ignore_changes = [log_analytics_workspace_id]
  }
}

resource "azurerm_container_app" "this" {
  count = var.enable_litellm ? 1 : 0

  name                         = "${var.name_prefix}-litellm"
  container_app_environment_id = azurerm_container_app_environment.this[0].id
  resource_group_name          = var.resource_group_name
  revision_mode                = "Single"
  tags                         = local.tags

  identity {
    type = "SystemAssigned"
  }

  secret {
    name  = "litellm-master-key"
    value = local.litellm_master_key
  }

  template {
    min_replicas = var.min_replicas
    max_replicas = var.max_replicas

    container {
      name   = "litellm"
      image  = "ghcr.io/berriai/litellm:main-latest"
      cpu    = var.cpu
      memory = var.memory

      env {
        name  = "AZURE_API_BASE"
        value = var.foundry_endpoint
      }

      env {
        name  = "AZURE_API_VERSION"
        value = var.api_version
      }

      # Master key for proxy authentication
      env {
        name        = "LITELLM_MASTER_KEY"
        secret_name = "litellm-master-key"
      }

      env {
        name  = "LITELLM_CONFIG_YAML"
        value = local.litellm_config
      }

      command = [
        "/bin/sh", "-c",
        "echo \"$LITELLM_CONFIG_YAML\" > /tmp/config.yaml && exec litellm --config /tmp/config.yaml --port 4000 --detailed_debug",
      ]
    }
  }

  ingress {
    external_enabled = !var.enable_private_networking
    target_port      = 4000

    traffic_weight {
      percentage      = 100
      latest_revision = true
    }
  }
}
