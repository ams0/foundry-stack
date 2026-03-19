resource "random_password" "gateway_token" {
  count   = var.enable_openclaw && var.gateway_token == "" ? 1 : 0
  length  = 32
  special = false
}

locals {
  tags = var.tags

  gateway_token = var.gateway_token != "" ? var.gateway_token : (
    var.enable_openclaw ? random_password.gateway_token[0].result : ""
  )

  # Provider config — uses OpenClaw's ~/.openclaw/providers.json format
  openclaw_provider_config = jsonencode({
    "litellm-azure" = {
      baseUrl = "${var.litellm_endpoint}/v1"
      apiKey  = var.litellm_api_key
      api     = "openai-completions"
      models = [
        for m in var.model_config : {
          id        = m.id
          name      = m.name
          api       = "openai-completions"
          reasoning = m.reasoning
          input     = ["text"]
          cost = {
            input      = 0
            output     = 0
            cacheRead  = 0
            cacheWrite = 0
          }
          contextWindow = m.context_window
          maxTokens     = m.max_tokens
        }
      ]
    }
  })

  # Build openclaw.json config
  # Custom providers go under models.providers per OpenClaw docs
  openclaw_config = jsonencode({
    models = {
      mode = "merge"
      providers = {
        "litellm-azure" = {
          baseUrl = "${var.litellm_endpoint}/v1"
          apiKey  = var.litellm_api_key
          api     = "openai-completions"
          models = [
            for m in var.model_config : {
              id            = m.id
              name          = m.name
              reasoning     = m.reasoning
              contextWindow = m.context_window
              maxTokens     = m.max_tokens
            }
          ]
        }
      }
    }
    gateway = {
      port = 18789
      mode = "local"
      auth = {
        token = local.gateway_token
      }
      controlUi = {
        allowedOrigins                           = var.allowed_origins
        dangerouslyAllowHostHeaderOriginFallback = true
      }
    }
    browser = {
      enabled        = false
      defaultProfile = "default"
    }
    agents = {
      defaults = {
        workspace = "/home/node/.openclaw/workspace"
        model = {
          primary = length(var.model_config) > 0 ? "litellm-azure/${var.model_config[0].id}" : "litellm-azure/gpt-5"
        }
        userTimezone   = "UTC"
        timeoutSeconds = 600
        maxConcurrent  = 1
      }
    }
    session = {
      scope = "per-sender"
      store = "/home/node/.openclaw/sessions.json"
      reset = {
        mode        = "idle"
        idleMinutes = 60
      }
    }
    logging = {
      level           = "info"
      consoleStyle    = "compact"
      redactSensitive = "tools"
    }
  })

  # Use shared LiteLLM environment if provided, otherwise create own
  create_environment = var.enable_openclaw && var.create_own_environment
  environment_id     = local.create_environment ? azurerm_container_app_environment.this[0].id : var.container_app_environment_id

  # Build secrets list: litellm key + all user-provided secrets
  base_secrets = {
    "litellm-api-key" = var.litellm_api_key
    "provider-config" = local.openclaw_provider_config
    "openclaw-config" = local.openclaw_config
    "gateway-token"   = local.gateway_token
  }
  all_secrets = merge(local.base_secrets, var.extra_secrets)
}

# --- Own Container App Environment (only if not sharing with LiteLLM) ---

resource "azurerm_container_app_environment" "this" {
  count = local.create_environment ? 1 : 0

  name                           = "${var.name_prefix}-cae-openclaw"
  location                       = var.location
  resource_group_name            = var.resource_group_name
  infrastructure_subnet_id       = var.enable_private_networking ? var.subnet_id : null
  internal_load_balancer_enabled = var.enable_private_networking ? true : null

  tags = local.tags
}

# --- OpenClaw Container App ---

resource "azurerm_container_app" "this" {
  count = var.enable_openclaw ? 1 : 0

  name                         = "${var.name_prefix}-openclaw"
  container_app_environment_id = local.environment_id
  resource_group_name          = var.resource_group_name
  revision_mode                = "Single"
  tags                         = local.tags

  # Secrets block — litellm key, configs, and any user-provided secrets
  dynamic "secret" {
    for_each = local.all_secrets
    content {
      name  = secret.key
      value = secret.value
    }
  }

  template {
    min_replicas = 1
    max_replicas = 1 # OpenClaw is NOT horizontally scalable

    # Writable volume for OpenClaw data, sessions, workspace
    volume {
      name         = "openclaw-data"
      storage_type = "EmptyDir"
    }

    volume {
      name         = "tmp"
      storage_type = "EmptyDir"
    }

    container {
      name   = "openclaw"
      image  = var.image
      cpu    = var.cpu
      memory = var.memory

      # Mount writable volumes
      volume_mounts {
        name = "openclaw-data"
        path = "/home/node/.openclaw"
      }

      volume_mounts {
        name = "tmp"
        path = "/tmp"
      }

      # Write config to /tmp (not the data volume) so OpenClaw can't overwrite it,
      # then symlink it. OpenClaw will read but can't persist changes.
      command = ["/bin/sh", "-c"]
      args = [
        "mkdir -p /home/node/.openclaw/workspace && printenv OPENCLAW_CONFIG > /tmp/openclaw.json && printenv OPENCLAW_PROVIDERS > /tmp/providers.json && rm -f /home/node/.openclaw/openclaw.json /home/node/.openclaw/providers.json && cp /tmp/openclaw.json /home/node/.openclaw/openclaw.json && cp /tmp/providers.json /home/node/.openclaw/providers.json && exec docker-entrypoint.sh node openclaw.mjs gateway --bind lan --port 18789 --auth password --password $OPENCLAW_GATEWAY_PASSWORD",
      ]

      # LiteLLM connection
      env {
        name        = "OPENCLAW_CONFIG"
        secret_name = "openclaw-config"
      }

      env {
        name        = "OPENCLAW_PROVIDERS"
        secret_name = "provider-config"
      }

      # OpenAI-compatible env vars pointing to LiteLLM
      # This allows OpenClaw's built-in "openai" provider to work via LiteLLM
      env {
        name        = "OPENAI_API_KEY"
        secret_name = "litellm-api-key"
      }

      env {
        name  = "OPENAI_BASE_URL"
        value = "${var.litellm_endpoint}/v1"
      }

      # Gateway password — used by both the gateway server and the CLI client
      env {
        name        = "OPENCLAW_GATEWAY_PASSWORD"
        secret_name = "gateway-token"
      }

      # Pass all user-provided env vars.
      # For sensitive vars: value = the secret key name from extra_secrets
      dynamic "env" {
        for_each = var.extra_env
        content {
          name        = env.value.name
          value       = env.value.sensitive ? null : env.value.value
          secret_name = env.value.sensitive ? env.value.value : null
        }
      }
    }
  }

  ingress {
    external_enabled = !var.enable_private_networking
    target_port      = 18789

    traffic_weight {
      percentage      = 100
      latest_revision = true
    }
  }
}
