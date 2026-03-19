# Azure AI Foundry Terraform Module — Design Spec

## Overview

Production-grade Terraform module to provision Azure AI Foundry and all supporting resources for a full RAG pipeline. Flat composable module structure — each Azure resource concern gets its own module, wired together via examples.

## Module Structure

```
modules/
  foundry/          # AI Foundry Hub + Project + AI Services + model deployments
  storage/          # Storage Account + RAG pipeline containers
  search/           # Azure AI Search
  redis/            # Azure Cache for Redis (optional, for Foundry model caching)
  keyvault/         # Key Vault
  networking/       # VNet, subnets, NSGs, private DNS zones
  monitoring/       # Log Analytics + App Insights + alerts + diagnostic settings
  apim/             # API Management (optional)
  litellm/          # Container App + LiteLLM proxy (optional)
  rbac/             # Cross-service role assignments

examples/
  complete/         # Full RAG-ready deployment, all modules
  minimal/          # Foundry + Storage + Key Vault + networking + monitoring

tests/              # Validation tests
```

### Dependency Graph

```
networking ─┬→ storage ──┬→ foundry ──→ rbac
            ├→ search ───┤
            ├→ redis ────┤  (optional)
            ├→ keyvault ─┤
            └→ monitoring ┘
                          foundry ──→ apim     (optional)
                          foundry ──→ litellm  (optional)
```

## Global Conventions

### Defaults

| Setting                  | Default         |
|--------------------------|-----------------|
| Region                   | `swedencentral` |
| `enable_private_networking` | `false`      |
| Tags                     | `SecurityControl=Ignore`, `CostControl=Ignore` |

### Resource Naming

All modules accept a `name_prefix` variable (e.g., `foundry-prod`). Resources are named `{name_prefix}-{service}` (e.g., `foundry-prod-storage`, `foundry-prod-search`). This avoids collisions and ensures consistency without requiring external naming modules.

### Resource Group

The resource group is **not** created by any child module. It must be created in the root/example module via `azurerm_resource_group` and passed as `resource_group_name` to all child modules. Examples will include this resource.

### Tenant ID

Modules that require `tenant_id` (Key Vault) source it internally via `data.azurerm_client_config.current.tenant_id`. No need to pass it as input.

### Lifecycle Protection

Stateful resources (Storage Account, Key Vault) include `lifecycle { prevent_destroy = true }` by default. A `enable_destroy_protection` variable (defaults to `true`) controls this — set to `false` for teardown scenarios.

### Tags

Every module defines:

```hcl
variable "tags" {
  type    = map(string)
  default = {}
}

locals {
  default_tags = {
    SecurityControl = "Ignore"
    CostControl     = "Ignore"
  }
  tags = merge(local.default_tags, var.tags)
}
```

All resources receive `tags = local.tags`.

### Private Networking Toggle

A single `enable_private_networking` boolean (defaults to `false`) controls:
- Whether the networking module creates VNet, subnets, NSGs, and private DNS zones
- Whether each service module creates its own `azurerm_private_endpoint`
- Whether service-level network rules deny public access

When `false`, all services are publicly accessible with their own firewall rules. When `true`, all services are locked behind private endpoints with no public access.

### Identity

Each module that creates a resource with a managed identity:
- Creates a system-assigned managed identity by default
- Accepts an optional `existing_identity_id` variable to use a user-assigned identity instead
- Outputs its principal ID for the RBAC module

### State Backend

Azure Storage Account backend. Configured by the consumer in the root/example backend blocks.

## Module Specifications

### `modules/networking`

**Resources:**
- `azurerm_virtual_network` — single VNet, default CIDR `10.0.0.0/16`
- `azurerm_subnet` — one per service:
  - `foundry` (`10.0.1.0/24`)
  - `storage` (`10.0.2.0/24`)
  - `search` (`10.0.3.0/24`)
  - `redis` (`10.0.4.0/24`)
  - `keyvault` (`10.0.5.0/24`)
  - `apim` (`10.0.6.0/24`)
  - `litellm` (`10.0.7.0/24`)
- `azurerm_network_security_group` — one per subnet, least-privilege inbound/outbound rules
- `azurerm_private_dns_zone` — one per service:
  - `privatelink.blob.core.windows.net` (Storage blob)
  - `privatelink.dfs.core.windows.net` (Storage DFS / Data Lake)
  - `privatelink.search.windows.net` (AI Search)
  - `privatelink.redis.cache.windows.net` (Redis)
  - `privatelink.vaultcore.azure.net` (Key Vault)
  - `privatelink.cognitiveservices.azure.com` (AI Services)
  - `privatelink.api.azureml.ms` (Foundry Hub API)
  - `privatelink.notebooks.azure.net` (Foundry Hub notebooks)
  - `privatelink.azure-api.net` (APIM, conditional on `enable_apim`)
  - `privatelink.{region}.azurecontainerapps.io` (Container Apps / LiteLLM, conditional on `enable_litellm`)
  - `privatelink.monitor.azure.com` (Azure Monitor)
  - `privatelink.oms.opinsights.azure.com` (Log Analytics)
  - `privatelink.ods.opinsights.azure.com` (Log Analytics data)
  - `privatelink.agentsvc.azure-automation.net` (Monitor agent)
- `azurerm_monitor_private_link_scope` — AMPLS for Log Analytics and App Insights (conditional)
- `azurerm_monitor_private_link_scoped_service` — scoped services for monitoring resources
- `azurerm_private_dns_zone_virtual_network_link` — link each zone to the VNet

**Inputs:** `enable_private_networking`, `resource_group_name`, `location`, `name_prefix`, `address_space`, `subnet_cidrs` (map with defaults), `enable_apim`, `enable_litellm`, `enable_redis`, `tags`
**Outputs:** VNet ID, subnet IDs map, DNS zone IDs map, NSG IDs map

All resources gated by `enable_private_networking`. When `false`, module produces empty outputs.

---

### `modules/storage`

**Resources:**
- `azurerm_storage_account` — Standard_LRS, Hot tier, TLS 1.2, HNS enabled (Data Lake Gen2 for RAG pipeline compatibility)
- `azurerm_storage_container` — `documents`, `chunks`, `embeddings`, `models`
- `azurerm_private_endpoint` — conditional on `enable_private_networking`
- `azurerm_storage_account_network_rules` — deny by default when private networking enabled

**Inputs:** `resource_group_name`, `location`, `name_prefix`, `enable_private_networking`, `subnet_id`, `dns_zone_ids` (blob + dfs), `tags`
**Outputs:** Storage Account ID, name, primary blob endpoint, primary DFS endpoint, primary access key (sensitive), containers map

**Defaults:** Standard_LRS, Hot tier, public blob access disabled

---

### `modules/search`

**Resources:**
- `azurerm_search_service` — Standard SKU (supports semantic ranking for RAG)
- `azurerm_private_endpoint` — conditional

**Inputs:** `resource_group_name`, `location`, `enable_private_networking`, `subnet_id`, `dns_zone_id`, `sku`, `replica_count`, `partition_count`, `tags`
**Outputs:** Search service ID, name, endpoint, primary key (sensitive), principal ID

**Defaults:** Standard SKU, 1 replica, 1 partition

---

### `modules/redis`

**Resources:**
- `azurerm_redis_cache` — Standard C1, TLS-only
- `azurerm_private_endpoint` — conditional

**Inputs:** `enable_redis`, `resource_group_name`, `location`, `name_prefix`, `enable_private_networking`, `subnet_id`, `dns_zone_id`, `sku_name`, `family`, `capacity`, `tags`
**Outputs:** Redis cache ID, hostname, port, primary access key (sensitive), connection string (sensitive)

**Defaults:** `enable_redis = false`, Standard SKU, C family, capacity 1, TLS 1.2 minimum, non-SSL port disabled

When `enable_redis = false`, no resources are created and outputs are empty/null.

When enabled and wired to Foundry: the Redis connection is passed to the Foundry Hub for model caching.

---

### `modules/keyvault`

**Resources:**
- `azurerm_key_vault` — RBAC authorization model, soft delete, purge protection
- `azurerm_private_endpoint` — conditional

**Inputs:** `resource_group_name`, `location`, `name_prefix`, `enable_private_networking`, `subnet_id`, `dns_zone_id`, `soft_delete_retention_days`, `tags`

Note: `tenant_id` is sourced internally via `data.azurerm_client_config.current.tenant_id`.
**Outputs:** Key Vault ID, name, URI, principal ID

**Defaults:** Standard SKU, 90-day soft delete, purge protection enabled

---

### `modules/foundry`

**Resources:**
- `azurerm_ai_foundry` — Hub resource, linked to Storage, Key Vault, Search, App Insights, optionally Redis
- `azurerm_ai_foundry_project` — one project under the Hub
- `azurerm_cognitive_account` (kind `AIServices`) — multi-service AI account
- `azurerm_cognitive_deployment` — one per entry in `model_deployments`
- `azurerm_private_endpoint` — conditional (Hub + AI Services)

**Inputs:**
- `resource_group_name`, `location`, `enable_private_networking`, `subnet_id`, `dns_zone_id`, `tags`
- `storage_account_id` — from storage module
- `key_vault_id` — from keyvault module
- `search_service_id` — from search module
- `application_insights_id` — from monitoring module
- `redis_cache_id` — optional, from redis module (when enabled, wires Foundry model caching)
- `existing_identity_id` — optional, use existing identity instead of system-assigned
- `model_deployments`:

```hcl
variable "model_deployments" {
  type = list(object({
    name          = string
    model_name    = string
    model_format  = optional(string, "OpenAI")
    model_version = string
    sku_name      = optional(string, "Standard")
    sku_capacity  = optional(number, 10)
  }))
  default = [
    {
      name          = "gpt-5"
      model_name    = "gpt-5"
      model_format  = "OpenAI"
      model_version = "latest"
    }
  ]
}
```

**Outputs:** Hub ID, Hub principal ID, Project ID, AI Services endpoint, AI Services principal ID, deployment endpoints map

---

### `modules/rbac`

**Resources:**
- `azurerm_role_assignment` — all cross-service permissions:

| Principal (from)       | Target (on)    | Role                             |
|------------------------|----------------|----------------------------------|
| Foundry Hub            | Storage        | Storage Blob Data Contributor    |
| Foundry Hub            | Key Vault      | Key Vault Secrets User           |
| Foundry Hub            | Search         | Search Index Data Reader         |
| Foundry AI Services    | Storage        | Storage Blob Data Contributor    |
| Foundry AI Services    | Search         | Search Index Data Contributor    |
| Foundry AI Services    | Search         | Search Service Contributor       |
| Foundry AI Services    | Key Vault      | Key Vault Secrets User           |
| Foundry AI Services    | Redis          | Redis Cache Contributor (if enabled) |

Note: Both the Hub and AI Services identities need separate role assignments — they are distinct managed identities.

**Inputs:**
- `foundry_hub_principal_id`
- `ai_services_principal_id`
- `storage_account_id`
- `search_service_id`
- `key_vault_id`
- `redis_cache_id` (optional)
- `redis_enabled`
- `additional_role_assignments` — list of `{ principal_id, role_definition_name, scope }` for custom assignments

**Outputs:** Role assignment IDs map

---

### `modules/monitoring`

**Resources:**
- `azurerm_log_analytics_workspace` — 30-day retention
- `azurerm_application_insights` — linked to Log Analytics
- `azurerm_monitor_diagnostic_setting` — one per monitored resource (Storage, Search, Redis, Key Vault, Foundry, APIM)
- `azurerm_monitor_metric_alert`:
  - Storage: availability < 99.9%, high latency
  - Search: throttled queries > 5%, high latency
  - Redis: memory > 80%, cache misses > 50% (when enabled)
  - Key Vault: availability < 99.9%
  - Foundry: failed requests > 5%
- `azurerm_monitor_action_group` — email and/or webhook

**Inputs:** `resource_group_name`, `location`, `retention_days`, `alert_email`, `resource_ids` (map of resource IDs to attach diagnostics to), `redis_enabled`, `tags`
**Outputs:** Log Analytics workspace ID, App Insights ID, App Insights instrumentation key, App Insights connection string

**Defaults:** 30-day retention, alerts enabled

---

### `modules/apim`

**Resources:**
- `azurerm_api_management` — Developer SKU, 1 unit
- `azurerm_api_management_api` — facade for Foundry endpoints
- `azurerm_api_management_policy` — rate limiting, JWT validation, logging
- `azurerm_private_endpoint` — conditional

**Inputs:** `enable_apim`, `resource_group_name`, `location`, `name_prefix`, `enable_private_networking`, `subnet_id`, `dns_zone_id`, `foundry_endpoint`, `sku_name`, `tags`
**Outputs:** APIM gateway URL, API ID

**Defaults:** `enable_apim = false`, Developer SKU, 1 unit

---

### `modules/litellm`

**Resources:**
- `azurerm_container_app_environment` — serverless
- `azurerm_container_app` — image `ghcr.io/berriai/litellm:main-latest`
- `azurerm_private_endpoint` — conditional on `enable_private_networking`
- Env vars / secrets from Key Vault for Foundry endpoint and credentials
- Ingress: OpenAI-compatible API endpoint

**Inputs:** `enable_litellm`, `resource_group_name`, `location`, `name_prefix`, `enable_private_networking`, `subnet_id`, `dns_zone_id`, `key_vault_id`, `foundry_endpoint`, `cpu`, `memory`, `min_replicas`, `max_replicas`, `tags`
**Outputs:** LiteLLM endpoint URL

**Defaults:** `enable_litellm = false`, 0.5 vCPU, 1Gi memory, min 1 / max 3 replicas

---

## Examples

### `examples/complete`

Deploys all modules. Single `variables.tf` with global overrides. Demonstrates full RAG pipeline: documents in Storage → indexed by Search → queried by Foundry with gpt-5 → optionally cached by Redis → optionally fronted by APIM or LiteLLM.

### `examples/minimal`

Deploys: networking, storage, keyvault, search, foundry, rbac, monitoring. No Redis, APIM, or LiteLLM.

## Terraform Version Constraints

- Terraform `>= 1.5`
- AzureRM provider `>= 4.0`
- Required providers block in each module

## File Convention Per Module

Each module contains:
- `main.tf` — resource definitions
- `variables.tf` — input variables with descriptions, types, defaults
- `outputs.tf` — output values
- `versions.tf` — required providers and version constraints
- `private_endpoint.tf` — private endpoint resources (conditional), kept separate for clarity
