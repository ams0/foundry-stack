# --- LLM backends (one per llm_backends entry, MI auth) ---

resource "azapi_resource" "llm_backend" {
  for_each = {
    for b in(var.enable_apim_policies ? var.llm_backends : []) : b.backend_id => b
  }

  type                      = "Microsoft.ApiManagement/service/backends@2024-06-01-preview"
  name                      = each.value.backend_id
  parent_id                 = var.api_management_id
  schema_validation_enabled = false

  body = {
    properties = merge(
      {
        description = "LLM Backend: ${each.value.backend_type} - ${each.value.backend_id} - Supports models: ${join(", ", [for m in each.value.supported_models : m.name])}"
        url         = each.value.endpoint
        protocol    = "http"
        credentials = {
          managedIdentity = merge(
            { resource = "https://cognitiveservices.azure.com" },
            var.apim_identity_client_id != "" ? { clientId = var.apim_identity_client_id } : {},
          )
          header = var.apim_identity_client_id != "" ? {
            "x-ms-client-id" = [var.apim_identity_client_id]
          } : {}
        }
        tls = {
          validateCertificateChain = true
          validateCertificateName  = true
        }
      },
      var.configure_circuit_breaker ? {
        circuitBreaker = {
          rules = [
            {
              name             = "${each.value.backend_id}-breaker-rule"
              tripDuration     = "PT1M"
              acceptRetryAfter = true
              failureCondition = {
                count        = 3
                errorReasons = ["Server errors"]
                interval     = "PT5M"
                statusCodeRanges = [
                  { min = 429, max = 429 },
                  { min = 500, max = 503 },
                ]
              }
            }
          ]
        }
      } : {},
    )
  }
}

# --- Backend pools (only for models served by 2+ backends) ---

resource "azapi_resource" "backend_pool" {
  for_each = {
    for p in(var.enable_apim_policies ? local.pool_configs : []) : p.pool_name => p
  }

  type      = "Microsoft.ApiManagement/service/backends@2024-06-01-preview"
  name      = each.value.pool_name
  parent_id = var.api_management_id

  body = {
    properties = {
      description = "Backend pool for model: ${each.value.model_name}"
      type        = "Pool"
      pool = {
        services = [
          for b in each.value.backends : {
            id       = "/backends/${b.backend_id}"
            priority = b.priority
            weight   = b.weight
          }
        ]
      }
    }
  }

  depends_on = [azapi_resource.llm_backend]
}

# --- Embeddings backend (optional, dedicated MI auth) ---

resource "azapi_resource" "embeddings_backend" {
  count = var.enable_apim_policies && var.enable_embeddings_backend ? 1 : 0

  type                      = "Microsoft.ApiManagement/service/backends@2024-06-01-preview"
  name                      = var.embeddings_backend_id
  parent_id                 = var.api_management_id
  schema_validation_enabled = false

  body = {
    properties = {
      description = "AI Foundry embeddings backend"
      url         = var.embeddings_backend_url
      protocol    = "http"
      credentials = {
        managedIdentity = merge(
          { resource = "https://cognitiveservices.azure.com" },
          var.apim_identity_client_id != "" ? { clientId = var.apim_identity_client_id } : {},
        )
      }
      tls = {
        validateCertificateChain = true
        validateCertificateName  = true
      }
    }
  }
}

# --- Content Safety backend (MI auth, referenced by content-safety policies) ---

resource "azapi_resource" "content_safety_backend" {
  count = var.enable_apim_policies && var.enable_content_safety_backend ? 1 : 0

  type                      = "Microsoft.ApiManagement/service/backends@2024-05-01"
  name                      = "content-safety-backend"
  parent_id                 = var.api_management_id
  schema_validation_enabled = false

  body = {
    properties = {
      description = "Content Safety Service Backend"
      url         = var.content_safety_service_url
      protocol    = "http"
      credentials = {
        managedIdentity = merge(
          { resource = "https://cognitiveservices.azure.com" },
          var.apim_identity_client_id != "" ? { clientId = var.apim_identity_client_id } : {},
        )
      }
      tls = {
        validateCertificateChain = true
        validateCertificateName  = true
      }
    }
  }
}

# --- APIM external cache (Redis) ---

resource "azapi_resource" "redis_cache" {
  count = var.enable_apim_policies && var.enable_redis_cache ? 1 : 0

  type      = "Microsoft.ApiManagement/service/caches@2024-06-01-preview"
  name      = var.redis_cache_name
  parent_id = var.api_management_id

  body = {
    properties = {
      connectionString = var.redis_cache_connection_string
      useFromLocation  = "default"
      description      = "Azure Managed Redis cache for APIM Semantic Cache"
    }
  }
}
