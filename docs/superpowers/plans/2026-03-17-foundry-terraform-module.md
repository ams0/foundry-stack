# Azure AI Foundry Terraform Module — Implementation Plan

> **For agentic workers:** REQUIRED: Use superpowers:subagent-driven-development (if subagents available) or superpowers:executing-plans to implement this plan. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Scaffold a production-grade Terraform module to provision Azure AI Foundry and all supporting resources for a full RAG pipeline.

**Architecture:** Flat composable modules under `modules/`, each owning one Azure resource concern. Modules are wired together in `examples/`. All modules follow identical file conventions (`main.tf`, `variables.tf`, `outputs.tf`, `versions.tf`, `private_endpoint.tf`). A single `enable_private_networking` toggle controls the entire networking posture.

**Tech Stack:** Terraform >= 1.5, AzureRM provider >= 4.0

**Spec:** `docs/superpowers/specs/2026-03-17-foundry-terraform-module-design.md`

---

## File Map

```
modules/
  networking/
    main.tf              # VNet, subnets, NSGs, DNS zones, AMPLS
    variables.tf         # enable_private_networking, CIDRs, feature flags
    outputs.tf           # VNet ID, subnet IDs map, DNS zone IDs map
    versions.tf          # Provider requirements
  storage/
    main.tf              # Storage account + containers
    variables.tf         # name_prefix, networking inputs, tags
    outputs.tf           # Account ID, endpoints, containers
    versions.tf
    private_endpoint.tf  # Conditional PE for blob + dfs
  search/
    main.tf              # AI Search service
    variables.tf
    outputs.tf
    versions.tf
    private_endpoint.tf
  redis/
    main.tf              # Redis cache (conditional)
    variables.tf
    outputs.tf
    versions.tf
    private_endpoint.tf
  keyvault/
    main.tf              # Key Vault
    variables.tf
    outputs.tf
    versions.tf
    private_endpoint.tf
  foundry/
    main.tf              # AI Foundry Hub + Project + AI Services + deployments
    variables.tf
    outputs.tf
    versions.tf
    private_endpoint.tf
  rbac/
    main.tf              # All cross-service role assignments
    variables.tf
    outputs.tf
    versions.tf
  monitoring/
    main.tf              # Log Analytics + App Insights + diagnostics + alerts
    variables.tf
    outputs.tf
    versions.tf
  apim/
    main.tf              # API Management (conditional)
    variables.tf
    outputs.tf
    versions.tf
    private_endpoint.tf
  litellm/
    main.tf              # Container App + LiteLLM (conditional)
    variables.tf
    outputs.tf
    versions.tf
    private_endpoint.tf
examples/
  complete/
    main.tf              # Wires all modules
    variables.tf         # Global overrides
    outputs.tf
    versions.tf
    terraform.tfvars.example
  minimal/
    main.tf
    variables.tf
    outputs.tf
    versions.tf
    terraform.tfvars.example
```

---

## Chunk 1: Project Scaffolding + Networking Module

### Task 1: Root structure and shared versions pattern

**Files:**
- Create: `modules/networking/versions.tf`
- Create: `modules/networking/variables.tf`
- Create: `modules/networking/main.tf`
- Create: `modules/networking/outputs.tf`

Every module shares the same `versions.tf` pattern. We start with networking since it has zero dependencies.

- [ ] **Step 1: Create the versions.tf template**

Create `modules/networking/versions.tf`:

```hcl
terraform {
  required_version = ">= 1.5"

  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = ">= 4.0"
    }
  }
}
```

- [ ] **Step 2: Create networking variables.tf**

Create `modules/networking/variables.tf`:

```hcl
variable "resource_group_name" {
  description = "Name of the resource group"
  type        = string
}

variable "location" {
  description = "Azure region"
  type        = string
  default     = "swedencentral"
}

variable "name_prefix" {
  description = "Prefix for all resource names"
  type        = string
}

variable "enable_private_networking" {
  description = "Enable VNet, subnets, NSGs, private DNS zones, and private endpoints"
  type        = bool
  default     = false
}

variable "address_space" {
  description = "VNet address space"
  type        = list(string)
  default     = ["10.0.0.0/16"]
}

variable "subnet_cidrs" {
  description = "CIDR blocks for each service subnet"
  type        = map(string)
  default = {
    foundry  = "10.0.1.0/24"
    storage  = "10.0.2.0/24"
    search   = "10.0.3.0/24"
    redis    = "10.0.4.0/24"
    keyvault = "10.0.5.0/24"
    apim     = "10.0.6.0/24"
    litellm  = "10.0.7.0/24"
  }
}

variable "enable_redis" {
  description = "Whether Redis resources are enabled (controls DNS zone creation)"
  type        = bool
  default     = false
}

variable "enable_apim" {
  description = "Whether APIM resources are enabled (controls DNS zone creation)"
  type        = bool
  default     = false
}

variable "enable_litellm" {
  description = "Whether LiteLLM resources are enabled (controls DNS zone creation)"
  type        = bool
  default     = false
}

variable "tags" {
  description = "Additional tags to merge with defaults"
  type        = map(string)
  default     = {}
}
```

- [ ] **Step 3: Create networking main.tf**

Create `modules/networking/main.tf`:

```hcl
locals {
  default_tags = {
    SecurityControl = "Ignore"
    CostControl     = "Ignore"
  }
  tags = merge(local.default_tags, var.tags)

  # Core DNS zones always created when private networking is enabled
  core_dns_zones = {
    blob           = "privatelink.blob.core.windows.net"
    dfs            = "privatelink.dfs.core.windows.net"
    search         = "privatelink.search.windows.net"
    keyvault       = "privatelink.vaultcore.azure.net"
    cognitiveservices = "privatelink.cognitiveservices.azure.com"
    foundry_api    = "privatelink.api.azureml.ms"
    foundry_notebooks = "privatelink.notebooks.azure.net"
    monitor        = "privatelink.monitor.azure.com"
    oms            = "privatelink.oms.opinsights.azure.com"
    ods            = "privatelink.ods.opinsights.azure.com"
    agentsvc       = "privatelink.agentsvc.azure-automation.net"
  }

  # Conditional DNS zones based on feature flags
  optional_dns_zones = merge(
    var.enable_redis ? { redis = "privatelink.redis.cache.windows.net" } : {},
    var.enable_apim ? { apim = "privatelink.azure-api.net" } : {},
    var.enable_litellm ? { litellm = "privatelink.${var.location}.azurecontainerapps.io" } : {},
  )

  all_dns_zones = var.enable_private_networking ? merge(local.core_dns_zones, local.optional_dns_zones) : {}

  # Only create subnets for enabled services
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
  )

  all_subnets = var.enable_private_networking ? merge(local.core_subnets, local.optional_subnets) : {}
}

# --- VNet ---

resource "azurerm_virtual_network" "this" {
  count = var.enable_private_networking ? 1 : 0

  name                = "${var.name_prefix}-vnet"
  location            = var.location
  resource_group_name = var.resource_group_name
  address_space       = var.address_space
  tags                = local.tags
}

# --- Subnets ---

resource "azurerm_subnet" "this" {
  for_each = local.all_subnets

  name                 = "${var.name_prefix}-snet-${each.key}"
  resource_group_name  = var.resource_group_name
  virtual_network_name = azurerm_virtual_network.this[0].name
  address_prefixes     = [each.value]
}

# --- NSGs ---

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

# --- Private DNS Zones ---

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

# --- Azure Monitor Private Link Scope (AMPLS) ---

resource "azurerm_monitor_private_link_scope" "this" {
  count = var.enable_private_networking ? 1 : 0

  name                = "${var.name_prefix}-ampls"
  resource_group_name = var.resource_group_name
  tags                = local.tags
}
```

- [ ] **Step 4: Create networking outputs.tf**

Create `modules/networking/outputs.tf`:

```hcl
output "vnet_id" {
  description = "ID of the virtual network"
  value       = var.enable_private_networking ? azurerm_virtual_network.this[0].id : null
}

output "subnet_ids" {
  description = "Map of subnet name to subnet ID"
  value       = { for k, v in azurerm_subnet.this : k => v.id }
}

output "dns_zone_ids" {
  description = "Map of DNS zone key to DNS zone ID"
  value       = { for k, v in azurerm_private_dns_zone.this : k => v.id }
}

output "nsg_ids" {
  description = "Map of NSG name to NSG ID"
  value       = { for k, v in azurerm_network_security_group.this : k => v.id }
}

output "ampls_id" {
  description = "ID of the Azure Monitor Private Link Scope"
  value       = var.enable_private_networking ? azurerm_monitor_private_link_scope.this[0].id : null
}
```

- [ ] **Step 5: Validate networking module**

```bash
cd modules/networking && terraform init -backend=false && terraform validate && terraform fmt -check -recursive
```

Expected: `Success! The configuration is valid.`

- [ ] **Step 6: Commit**

```bash
git add modules/networking/
git commit -m "feat: add networking module with VNet, subnets, NSGs, DNS zones, AMPLS"
```

---

## Chunk 2: Data Layer — Storage, Search, Redis, Key Vault

### Task 2: Storage module

**Files:**
- Create: `modules/storage/versions.tf`
- Create: `modules/storage/variables.tf`
- Create: `modules/storage/main.tf`
- Create: `modules/storage/outputs.tf`
- Create: `modules/storage/private_endpoint.tf`

- [ ] **Step 1: Create versions.tf**

Same pattern as networking — copy and create `modules/storage/versions.tf`.

- [ ] **Step 2: Create storage variables.tf**

Create `modules/storage/variables.tf`:

```hcl
variable "resource_group_name" {
  description = "Name of the resource group"
  type        = string
}

variable "location" {
  description = "Azure region"
  type        = string
  default     = "swedencentral"
}

variable "name_prefix" {
  description = "Prefix for resource names"
  type        = string
}

variable "enable_private_networking" {
  description = "Enable private endpoint and deny public access"
  type        = bool
  default     = false
}

variable "subnet_id" {
  description = "Subnet ID for private endpoint (required if enable_private_networking=true)"
  type        = string
  default     = null
}

variable "dns_zone_ids" {
  description = "Map of DNS zone IDs: keys 'blob' and 'dfs'"
  type        = map(string)
  default     = {}
}

variable "account_replication_type" {
  description = "Storage account replication type"
  type        = string
  default     = "LRS"
}

variable "account_tier" {
  description = "Storage account tier"
  type        = string
  default     = "Standard"
}

variable "containers" {
  description = "List of blob containers to create"
  type        = list(string)
  default     = ["documents", "chunks", "embeddings", "models"]
}

variable "tags" {
  description = "Additional tags to merge with defaults"
  type        = map(string)
  default     = {}
}
```

- [ ] **Step 3: Create storage main.tf**

Create `modules/storage/main.tf`:

```hcl
locals {
  default_tags = {
    SecurityControl = "Ignore"
    CostControl     = "Ignore"
  }
  tags = merge(local.default_tags, var.tags)

  # Storage account names must be 3-24 chars, lowercase alphanumeric only
  storage_account_name = replace("${var.name_prefix}storage", "-", "")
}

resource "azurerm_storage_account" "this" {
  name                     = substr(local.storage_account_name, 0, 24)
  resource_group_name      = var.resource_group_name
  location                 = var.location
  account_tier             = var.account_tier
  account_replication_type = var.account_replication_type
  is_hns_enabled           = true
  min_tls_version          = "TLS1_2"

  allow_nested_items_to_be_public = false
  public_network_access_enabled   = !var.enable_private_networking

  identity {
    type = "SystemAssigned"
  }

  tags = local.tags

  lifecycle {
    prevent_destroy = false # Controlled via enable_destroy_protection at plan level
  }
}

resource "azurerm_storage_container" "this" {
  for_each = toset(var.containers)

  name                 = each.value
  storage_account_id   = azurerm_storage_account.this.id
  container_access_type = "private"
}

resource "azurerm_storage_account_network_rules" "this" {
  count = var.enable_private_networking ? 1 : 0

  storage_account_id = azurerm_storage_account.this.id
  default_action     = "Deny"
  bypass             = ["AzureServices"]
}
```

- [ ] **Step 4: Create storage private_endpoint.tf**

Create `modules/storage/private_endpoint.tf`:

```hcl
resource "azurerm_private_endpoint" "blob" {
  count = var.enable_private_networking ? 1 : 0

  name                = "${var.name_prefix}-pe-blob"
  location            = var.location
  resource_group_name = var.resource_group_name
  subnet_id           = var.subnet_id
  tags                = local.tags

  private_service_connection {
    name                           = "${var.name_prefix}-psc-blob"
    private_connection_resource_id = azurerm_storage_account.this.id
    subresource_names              = ["blob"]
    is_manual_connection           = false
  }

  private_dns_zone_group {
    name                 = "blob-dns"
    private_dns_zone_ids = [var.dns_zone_ids["blob"]]
  }
}

resource "azurerm_private_endpoint" "dfs" {
  count = var.enable_private_networking ? 1 : 0

  name                = "${var.name_prefix}-pe-dfs"
  location            = var.location
  resource_group_name = var.resource_group_name
  subnet_id           = var.subnet_id
  tags                = local.tags

  private_service_connection {
    name                           = "${var.name_prefix}-psc-dfs"
    private_connection_resource_id = azurerm_storage_account.this.id
    subresource_names              = ["dfs"]
    is_manual_connection           = false
  }

  private_dns_zone_group {
    name                 = "dfs-dns"
    private_dns_zone_ids = [var.dns_zone_ids["dfs"]]
  }
}
```

- [ ] **Step 5: Create storage outputs.tf**

Create `modules/storage/outputs.tf`:

```hcl
output "storage_account_id" {
  description = "Storage account resource ID"
  value       = azurerm_storage_account.this.id
}

output "storage_account_name" {
  description = "Storage account name"
  value       = azurerm_storage_account.this.name
}

output "primary_blob_endpoint" {
  description = "Primary blob service endpoint"
  value       = azurerm_storage_account.this.primary_blob_endpoint
}

output "primary_dfs_endpoint" {
  description = "Primary DFS (Data Lake) endpoint"
  value       = azurerm_storage_account.this.primary_dfs_endpoint
}

output "primary_access_key" {
  description = "Primary access key"
  value       = azurerm_storage_account.this.primary_access_key
  sensitive   = true
}

output "principal_id" {
  description = "System-assigned managed identity principal ID"
  value       = azurerm_storage_account.this.identity[0].principal_id
}

output "containers" {
  description = "Map of container name to container resource"
  value       = { for k, v in azurerm_storage_container.this : k => v.name }
}
```

- [ ] **Step 6: Validate storage module**

```bash
cd modules/storage && terraform init -backend=false && terraform validate && terraform fmt -check -recursive
```

- [ ] **Step 7: Commit**

```bash
git add modules/storage/
git commit -m "feat: add storage module with Data Lake Gen2, containers, private endpoints"
```

---

### Task 3: Search module

**Files:**
- Create: `modules/search/versions.tf`
- Create: `modules/search/variables.tf`
- Create: `modules/search/main.tf`
- Create: `modules/search/outputs.tf`
- Create: `modules/search/private_endpoint.tf`

- [ ] **Step 1: Create all search module files**

Create `modules/search/versions.tf` (same pattern).

Create `modules/search/variables.tf`:

```hcl
variable "resource_group_name" {
  description = "Name of the resource group"
  type        = string
}

variable "location" {
  description = "Azure region"
  type        = string
  default     = "swedencentral"
}

variable "name_prefix" {
  description = "Prefix for resource names"
  type        = string
}

variable "enable_private_networking" {
  description = "Enable private endpoint and deny public access"
  type        = bool
  default     = false
}

variable "subnet_id" {
  description = "Subnet ID for private endpoint"
  type        = string
  default     = null
}

variable "dns_zone_id" {
  description = "Private DNS zone ID for search"
  type        = string
  default     = null
}

variable "sku" {
  description = "Search service SKU"
  type        = string
  default     = "standard"
}

variable "replica_count" {
  description = "Number of search replicas"
  type        = number
  default     = 1
}

variable "partition_count" {
  description = "Number of search partitions"
  type        = number
  default     = 1
}

variable "tags" {
  description = "Additional tags to merge with defaults"
  type        = map(string)
  default     = {}
}
```

Create `modules/search/main.tf`:

```hcl
locals {
  default_tags = {
    SecurityControl = "Ignore"
    CostControl     = "Ignore"
  }
  tags = merge(local.default_tags, var.tags)
}

resource "azurerm_search_service" "this" {
  name                          = "${var.name_prefix}-search"
  resource_group_name           = var.resource_group_name
  location                      = var.location
  sku                           = var.sku
  replica_count                 = var.replica_count
  partition_count               = var.partition_count
  public_network_access_enabled = !var.enable_private_networking
  semantic_search_sku           = "standard"

  identity {
    type = "SystemAssigned"
  }

  tags = local.tags
}
```

Create `modules/search/private_endpoint.tf`:

```hcl
resource "azurerm_private_endpoint" "this" {
  count = var.enable_private_networking ? 1 : 0

  name                = "${var.name_prefix}-pe-search"
  location            = var.location
  resource_group_name = var.resource_group_name
  subnet_id           = var.subnet_id
  tags                = local.tags

  private_service_connection {
    name                           = "${var.name_prefix}-psc-search"
    private_connection_resource_id = azurerm_search_service.this.id
    subresource_names              = ["searchService"]
    is_manual_connection           = false
  }

  private_dns_zone_group {
    name                 = "search-dns"
    private_dns_zone_ids = [var.dns_zone_id]
  }
}
```

Create `modules/search/outputs.tf`:

```hcl
output "search_service_id" {
  description = "Search service resource ID"
  value       = azurerm_search_service.this.id
}

output "search_service_name" {
  description = "Search service name"
  value       = azurerm_search_service.this.name
}

output "endpoint" {
  description = "Search service endpoint URL"
  value       = "https://${azurerm_search_service.this.name}.search.windows.net"
}

output "primary_key" {
  description = "Search service primary admin key"
  value       = azurerm_search_service.this.primary_key
  sensitive   = true
}

output "principal_id" {
  description = "System-assigned managed identity principal ID"
  value       = azurerm_search_service.this.identity[0].principal_id
}
```

- [ ] **Step 2: Validate search module**

```bash
cd modules/search && terraform init -backend=false && terraform validate && terraform fmt -check -recursive
```

- [ ] **Step 3: Commit**

```bash
git add modules/search/
git commit -m "feat: add search module with Azure AI Search, semantic ranking, private endpoint"
```

---

### Task 4: Redis module (optional)

**Files:**
- Create: `modules/redis/versions.tf`
- Create: `modules/redis/variables.tf`
- Create: `modules/redis/main.tf`
- Create: `modules/redis/outputs.tf`
- Create: `modules/redis/private_endpoint.tf`

- [ ] **Step 1: Create all redis module files**

Create `modules/redis/versions.tf` (same pattern).

Create `modules/redis/variables.tf`:

```hcl
variable "enable_redis" {
  description = "Whether to create Redis resources"
  type        = bool
  default     = false
}

variable "resource_group_name" {
  description = "Name of the resource group"
  type        = string
}

variable "location" {
  description = "Azure region"
  type        = string
  default     = "swedencentral"
}

variable "name_prefix" {
  description = "Prefix for resource names"
  type        = string
}

variable "enable_private_networking" {
  description = "Enable private endpoint"
  type        = bool
  default     = false
}

variable "subnet_id" {
  description = "Subnet ID for private endpoint"
  type        = string
  default     = null
}

variable "dns_zone_id" {
  description = "Private DNS zone ID for Redis"
  type        = string
  default     = null
}

variable "sku_name" {
  description = "Redis SKU name"
  type        = string
  default     = "Standard"
}

variable "family" {
  description = "Redis family"
  type        = string
  default     = "C"
}

variable "capacity" {
  description = "Redis cache capacity"
  type        = number
  default     = 1
}

variable "tags" {
  description = "Additional tags to merge with defaults"
  type        = map(string)
  default     = {}
}
```

Create `modules/redis/main.tf`:

```hcl
locals {
  default_tags = {
    SecurityControl = "Ignore"
    CostControl     = "Ignore"
  }
  tags = merge(local.default_tags, var.tags)
}

resource "azurerm_redis_cache" "this" {
  count = var.enable_redis ? 1 : 0

  name                          = "${var.name_prefix}-redis"
  location                      = var.location
  resource_group_name           = var.resource_group_name
  capacity                      = var.capacity
  family                        = var.family
  sku_name                      = var.sku_name
  non_ssl_port_enabled          = false
  minimum_tls_version           = "1.2"
  public_network_access_enabled = !var.enable_private_networking

  redis_configuration {}

  tags = local.tags
}
```

Create `modules/redis/private_endpoint.tf`:

```hcl
resource "azurerm_private_endpoint" "this" {
  count = var.enable_redis && var.enable_private_networking ? 1 : 0

  name                = "${var.name_prefix}-pe-redis"
  location            = var.location
  resource_group_name = var.resource_group_name
  subnet_id           = var.subnet_id
  tags                = local.tags

  private_service_connection {
    name                           = "${var.name_prefix}-psc-redis"
    private_connection_resource_id = azurerm_redis_cache.this[0].id
    subresource_names              = ["redisCache"]
    is_manual_connection           = false
  }

  private_dns_zone_group {
    name                 = "redis-dns"
    private_dns_zone_ids = [var.dns_zone_id]
  }
}
```

Create `modules/redis/outputs.tf`:

```hcl
output "redis_cache_id" {
  description = "Redis cache resource ID"
  value       = var.enable_redis ? azurerm_redis_cache.this[0].id : null
}

output "hostname" {
  description = "Redis cache hostname"
  value       = var.enable_redis ? azurerm_redis_cache.this[0].hostname : null
}

output "port" {
  description = "Redis SSL port"
  value       = var.enable_redis ? azurerm_redis_cache.this[0].ssl_port : null
}

output "primary_access_key" {
  description = "Redis primary access key"
  value       = var.enable_redis ? azurerm_redis_cache.this[0].primary_access_key : null
  sensitive   = true
}

output "primary_connection_string" {
  description = "Redis primary connection string"
  value       = var.enable_redis ? azurerm_redis_cache.this[0].primary_connection_string : null
  sensitive   = true
}
```

- [ ] **Step 2: Validate redis module**

```bash
cd modules/redis && terraform init -backend=false && terraform validate && terraform fmt -check -recursive
```

- [ ] **Step 3: Commit**

```bash
git add modules/redis/
git commit -m "feat: add redis module with optional Azure Cache for Redis, private endpoint"
```

---

### Task 5: Key Vault module

**Files:**
- Create: `modules/keyvault/versions.tf`
- Create: `modules/keyvault/variables.tf`
- Create: `modules/keyvault/main.tf`
- Create: `modules/keyvault/outputs.tf`
- Create: `modules/keyvault/private_endpoint.tf`

- [ ] **Step 1: Create all keyvault module files**

Create `modules/keyvault/versions.tf` (same pattern).

Create `modules/keyvault/variables.tf`:

```hcl
variable "resource_group_name" {
  description = "Name of the resource group"
  type        = string
}

variable "location" {
  description = "Azure region"
  type        = string
  default     = "swedencentral"
}

variable "name_prefix" {
  description = "Prefix for resource names"
  type        = string
}

variable "enable_private_networking" {
  description = "Enable private endpoint and deny public access"
  type        = bool
  default     = false
}

variable "subnet_id" {
  description = "Subnet ID for private endpoint"
  type        = string
  default     = null
}

variable "dns_zone_id" {
  description = "Private DNS zone ID for Key Vault"
  type        = string
  default     = null
}

variable "soft_delete_retention_days" {
  description = "Number of days to retain soft-deleted vaults"
  type        = number
  default     = 90
}

variable "tags" {
  description = "Additional tags to merge with defaults"
  type        = map(string)
  default     = {}
}
```

Create `modules/keyvault/main.tf`:

```hcl
locals {
  default_tags = {
    SecurityControl = "Ignore"
    CostControl     = "Ignore"
  }
  tags = merge(local.default_tags, var.tags)
}

data "azurerm_client_config" "current" {}

resource "azurerm_key_vault" "this" {
  name                = "${var.name_prefix}-kv"
  location            = var.location
  resource_group_name = var.resource_group_name
  tenant_id           = data.azurerm_client_config.current.tenant_id
  sku_name            = "standard"

  rbac_authorization_enabled    = true
  purge_protection_enabled      = true
  soft_delete_retention_days    = var.soft_delete_retention_days
  public_network_access_enabled = !var.enable_private_networking

  tags = local.tags

  lifecycle {
    prevent_destroy = false # Controlled via enable_destroy_protection at plan level
  }
}
```

Create `modules/keyvault/private_endpoint.tf`:

```hcl
resource "azurerm_private_endpoint" "this" {
  count = var.enable_private_networking ? 1 : 0

  name                = "${var.name_prefix}-pe-kv"
  location            = var.location
  resource_group_name = var.resource_group_name
  subnet_id           = var.subnet_id
  tags                = local.tags

  private_service_connection {
    name                           = "${var.name_prefix}-psc-kv"
    private_connection_resource_id = azurerm_key_vault.this.id
    subresource_names              = ["vault"]
    is_manual_connection           = false
  }

  private_dns_zone_group {
    name                 = "kv-dns"
    private_dns_zone_ids = [var.dns_zone_id]
  }
}
```

Create `modules/keyvault/outputs.tf`:

```hcl
output "key_vault_id" {
  description = "Key Vault resource ID"
  value       = azurerm_key_vault.this.id
}

output "key_vault_name" {
  description = "Key Vault name"
  value       = azurerm_key_vault.this.name
}

output "key_vault_uri" {
  description = "Key Vault URI"
  value       = azurerm_key_vault.this.vault_uri
}
```

- [ ] **Step 2: Validate keyvault module**

```bash
cd modules/keyvault && terraform init -backend=false && terraform validate && terraform fmt -check -recursive
```

- [ ] **Step 3: Commit**

```bash
git add modules/keyvault/
git commit -m "feat: add keyvault module with RBAC auth, purge protection, private endpoint"
```

---

## Chunk 3: Monitoring Module

### Task 6: Monitoring module

**Files:**
- Create: `modules/monitoring/versions.tf`
- Create: `modules/monitoring/variables.tf`
- Create: `modules/monitoring/main.tf`
- Create: `modules/monitoring/outputs.tf`

- [ ] **Step 1: Create all monitoring module files**

Create `modules/monitoring/versions.tf` (same pattern).

Create `modules/monitoring/variables.tf`:

```hcl
variable "resource_group_name" {
  description = "Name of the resource group"
  type        = string
}

variable "location" {
  description = "Azure region"
  type        = string
  default     = "swedencentral"
}

variable "name_prefix" {
  description = "Prefix for resource names"
  type        = string
}

variable "retention_days" {
  description = "Log Analytics workspace retention in days"
  type        = number
  default     = 30
}

variable "alert_email" {
  description = "Email address for alert notifications (optional)"
  type        = string
  default     = null
}

variable "resource_ids" {
  description = "Map of resource name to resource ID for diagnostic settings"
  type        = map(string)
  default     = {}
}

variable "enable_redis" {
  description = "Whether Redis alerts should be created"
  type        = bool
  default     = false
}

variable "tags" {
  description = "Additional tags to merge with defaults"
  type        = map(string)
  default     = {}
}
```

Create `modules/monitoring/main.tf`:

```hcl
locals {
  default_tags = {
    SecurityControl = "Ignore"
    CostControl     = "Ignore"
  }
  tags = merge(local.default_tags, var.tags)
}

# --- Log Analytics Workspace ---

resource "azurerm_log_analytics_workspace" "this" {
  name                = "${var.name_prefix}-law"
  location            = var.location
  resource_group_name = var.resource_group_name
  sku                 = "PerGB2018"
  retention_in_days   = var.retention_days
  tags                = local.tags
}

# --- Application Insights ---

resource "azurerm_application_insights" "this" {
  name                = "${var.name_prefix}-appi"
  location            = var.location
  resource_group_name = var.resource_group_name
  workspace_id        = azurerm_log_analytics_workspace.this.id
  application_type    = "web"
  tags                = local.tags
}

# --- Diagnostic Settings ---

resource "azurerm_monitor_diagnostic_setting" "this" {
  for_each = var.resource_ids

  name                       = "${each.key}-diag"
  target_resource_id         = each.value
  log_analytics_workspace_id = azurerm_log_analytics_workspace.this.id

  enabled_log {
    category_group = "allLogs"
  }

  metric {
    category = "AllMetrics"
    enabled  = true
  }
}

# --- Action Group ---

resource "azurerm_monitor_action_group" "this" {
  count = var.alert_email != null ? 1 : 0

  name                = "${var.name_prefix}-ag"
  resource_group_name = var.resource_group_name
  short_name          = substr(var.name_prefix, 0, 12)
  tags                = local.tags

  email_receiver {
    name          = "admin"
    email_address = var.alert_email
  }
}

# --- Metric Alerts ---

locals {
  action_group_id = var.alert_email != null ? azurerm_monitor_action_group.this[0].id : null

  # Build alert definitions dynamically based on available resources
  storage_alerts = contains(keys(var.resource_ids), "storage") ? {
    storage_availability = {
      resource_id      = var.resource_ids["storage"]
      metric_namespace = "Microsoft.Storage/storageAccounts"
      metric_name      = "Availability"
      operator         = "LessThan"
      threshold        = 99.9
      aggregation      = "Average"
      description      = "Storage availability below 99.9%"
    }
    storage_latency = {
      resource_id      = var.resource_ids["storage"]
      metric_namespace = "Microsoft.Storage/storageAccounts"
      metric_name      = "SuccessE2ELatency"
      operator         = "GreaterThan"
      threshold        = 1000
      aggregation      = "Average"
      description      = "Storage E2E latency above 1000ms"
    }
  } : {}

  search_alerts = contains(keys(var.resource_ids), "search") ? {
    search_throttled = {
      resource_id      = var.resource_ids["search"]
      metric_namespace = "Microsoft.Search/searchServices"
      metric_name      = "ThrottledSearchQueriesPercentage"
      operator         = "GreaterThan"
      threshold        = 5
      aggregation      = "Average"
      description      = "Search throttled queries above 5%"
    }
    search_latency = {
      resource_id      = var.resource_ids["search"]
      metric_namespace = "Microsoft.Search/searchServices"
      metric_name      = "SearchLatency"
      operator         = "GreaterThan"
      threshold        = 1000
      aggregation      = "Average"
      description      = "Search latency above 1000ms"
    }
  } : {}

  keyvault_alerts = contains(keys(var.resource_ids), "keyvault") ? {
    keyvault_availability = {
      resource_id      = var.resource_ids["keyvault"]
      metric_namespace = "Microsoft.KeyVault/vaults"
      metric_name      = "Availability"
      operator         = "LessThan"
      threshold        = 99.9
      aggregation      = "Average"
      description      = "Key Vault availability below 99.9%"
    }
  } : {}

  redis_alerts = var.enable_redis && contains(keys(var.resource_ids), "redis") ? {
    redis_memory = {
      resource_id      = var.resource_ids["redis"]
      metric_namespace = "Microsoft.Cache/redis"
      metric_name      = "usedmemorypercentage"
      operator         = "GreaterThan"
      threshold        = 80
      aggregation      = "Average"
      description      = "Redis memory usage above 80%"
    }
    redis_cache_misses = {
      resource_id      = var.resource_ids["redis"]
      metric_namespace = "Microsoft.Cache/redis"
      metric_name      = "cachemissrate"
      operator         = "GreaterThan"
      threshold        = 50
      aggregation      = "Average"
      description      = "Redis cache miss rate above 50%"
    }
  } : {}

  foundry_alerts = contains(keys(var.resource_ids), "foundry") ? {
    foundry_failed_requests = {
      resource_id      = var.resource_ids["foundry"]
      metric_namespace = "Microsoft.CognitiveServices/accounts"
      metric_name      = "ClientErrors"
      operator         = "GreaterThan"
      threshold        = 5
      aggregation      = "Total"
      description      = "Foundry AI Services client errors above 5%"
    }
  } : {}

  all_alerts = var.alert_email != null ? merge(
    local.storage_alerts,
    local.search_alerts,
    local.keyvault_alerts,
    local.redis_alerts,
    local.foundry_alerts,
  ) : {}
}

resource "azurerm_monitor_metric_alert" "this" {
  for_each = local.all_alerts

  name                = "${var.name_prefix}-alert-${each.key}"
  resource_group_name = var.resource_group_name
  scopes              = [each.value.resource_id]
  description         = each.value.description
  severity            = 2
  frequency           = "PT5M"
  window_size         = "PT15M"
  tags                = local.tags

  criteria {
    metric_namespace = each.value.metric_namespace
    metric_name      = each.value.metric_name
    aggregation      = each.value.aggregation
    operator         = each.value.operator
    threshold        = each.value.threshold
  }

  action {
    action_group_id = local.action_group_id
  }
}
```

Create `modules/monitoring/outputs.tf`:

```hcl
output "log_analytics_workspace_id" {
  description = "Log Analytics workspace resource ID"
  value       = azurerm_log_analytics_workspace.this.id
}

output "log_analytics_workspace_name" {
  description = "Log Analytics workspace name"
  value       = azurerm_log_analytics_workspace.this.name
}

output "application_insights_id" {
  description = "Application Insights resource ID"
  value       = azurerm_application_insights.this.id
}

output "application_insights_instrumentation_key" {
  description = "Application Insights instrumentation key"
  value       = azurerm_application_insights.this.instrumentation_key
  sensitive   = true
}

output "application_insights_connection_string" {
  description = "Application Insights connection string"
  value       = azurerm_application_insights.this.connection_string
  sensitive   = true
}
```

- [ ] **Step 2: Validate monitoring module**

```bash
cd modules/monitoring && terraform init -backend=false && terraform validate && terraform fmt -check -recursive
```

- [ ] **Step 3: Commit**

```bash
git add modules/monitoring/
git commit -m "feat: add monitoring module with Log Analytics, App Insights, diagnostics, alerts"
```

---

## Chunk 4: AI Layer — Foundry + RBAC

### Task 7: Foundry module

**Files:**
- Create: `modules/foundry/versions.tf`
- Create: `modules/foundry/variables.tf`
- Create: `modules/foundry/main.tf`
- Create: `modules/foundry/outputs.tf`
- Create: `modules/foundry/private_endpoint.tf`

- [ ] **Step 1: Create all foundry module files**

Create `modules/foundry/versions.tf` (same pattern).

Create `modules/foundry/variables.tf`:

```hcl
variable "resource_group_name" {
  description = "Name of the resource group"
  type        = string
}

variable "location" {
  description = "Azure region"
  type        = string
  default     = "swedencentral"
}

variable "name_prefix" {
  description = "Prefix for resource names"
  type        = string
}

variable "enable_private_networking" {
  description = "Enable private endpoints"
  type        = bool
  default     = false
}

variable "subnet_id" {
  description = "Subnet ID for private endpoints"
  type        = string
  default     = null
}

variable "dns_zone_ids" {
  description = "Map of DNS zone IDs: keys 'cognitiveservices', 'foundry_api', 'foundry_notebooks'"
  type        = map(string)
  default     = {}
}

variable "storage_account_id" {
  description = "Storage account ID to link to Hub"
  type        = string
}

variable "key_vault_id" {
  description = "Key Vault ID to link to Hub"
  type        = string
}

variable "application_insights_id" {
  description = "Application Insights ID to link to Hub"
  type        = string
  default     = null
}

variable "existing_identity_id" {
  description = "Existing user-assigned identity ID (optional, overrides system-assigned)"
  type        = string
  default     = null
}

variable "model_deployments" {
  description = "List of model deployments to create"
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

variable "tags" {
  description = "Additional tags to merge with defaults"
  type        = map(string)
  default     = {}
}
```

Create `modules/foundry/main.tf`:

```hcl
locals {
  default_tags = {
    SecurityControl = "Ignore"
    CostControl     = "Ignore"
  }
  tags = merge(local.default_tags, var.tags)

  use_system_identity = var.existing_identity_id == null
}

# --- AI Services (multi-service cognitive account) ---

resource "azurerm_ai_services" "this" {
  name                = "${var.name_prefix}-aiservices"
  location            = var.location
  resource_group_name = var.resource_group_name
  sku_name            = "S0"

  identity {
    type = "SystemAssigned"
  }

  tags = local.tags
}

# --- Model Deployments ---

resource "azurerm_cognitive_deployment" "this" {
  for_each = { for d in var.model_deployments : d.name => d }

  name                 = each.value.name
  cognitive_account_id = azurerm_ai_services.this.id

  model {
    format  = each.value.model_format
    name    = each.value.model_name
    version = each.value.model_version
  }

  sku {
    name     = each.value.sku_name
    capacity = each.value.sku_capacity
  }
}

# --- AI Foundry Hub ---

resource "azurerm_ai_foundry" "this" {
  name                   = "${var.name_prefix}-hub"
  location               = azurerm_ai_services.this.location
  resource_group_name    = var.resource_group_name
  storage_account_id     = var.storage_account_id
  key_vault_id           = var.key_vault_id
  application_insights_id = var.application_insights_id
  public_network_access  = var.enable_private_networking ? "Disabled" : "Enabled"

  identity {
    type = local.use_system_identity ? "SystemAssigned" : "UserAssigned"
    identity_ids = local.use_system_identity ? null : [var.existing_identity_id]
  }

  tags = local.tags
}

# --- AI Foundry Project ---

resource "azurerm_ai_foundry_project" "this" {
  name                = "${var.name_prefix}-project"
  location            = azurerm_ai_foundry.this.location
  ai_services_hub_id  = azurerm_ai_foundry.this.id

  identity {
    type = "SystemAssigned"
  }

  tags = local.tags
}
```

Create `modules/foundry/private_endpoint.tf`:

```hcl
# Private endpoint for AI Services
resource "azurerm_private_endpoint" "ai_services" {
  count = var.enable_private_networking ? 1 : 0

  name                = "${var.name_prefix}-pe-aiservices"
  location            = var.location
  resource_group_name = var.resource_group_name
  subnet_id           = var.subnet_id
  tags                = local.tags

  private_service_connection {
    name                           = "${var.name_prefix}-psc-aiservices"
    private_connection_resource_id = azurerm_ai_services.this.id
    subresource_names              = ["account"]
    is_manual_connection           = false
  }

  private_dns_zone_group {
    name                 = "aiservices-dns"
    private_dns_zone_ids = [var.dns_zone_ids["cognitiveservices"]]
  }
}

# Private endpoint for AI Foundry Hub
resource "azurerm_private_endpoint" "hub" {
  count = var.enable_private_networking ? 1 : 0

  name                = "${var.name_prefix}-pe-hub"
  location            = var.location
  resource_group_name = var.resource_group_name
  subnet_id           = var.subnet_id
  tags                = local.tags

  private_service_connection {
    name                           = "${var.name_prefix}-psc-hub"
    private_connection_resource_id = azurerm_ai_foundry.this.id
    subresource_names              = ["amlworkspace"]
    is_manual_connection           = false
  }

  private_dns_zone_group {
    name = "hub-dns"
    private_dns_zone_ids = [
      var.dns_zone_ids["foundry_api"],
      var.dns_zone_ids["foundry_notebooks"],
    ]
  }
}
```

Create `modules/foundry/outputs.tf`:

```hcl
output "hub_id" {
  description = "AI Foundry Hub resource ID"
  value       = azurerm_ai_foundry.this.id
}

output "hub_principal_id" {
  description = "AI Foundry Hub system-assigned identity principal ID"
  value       = azurerm_ai_foundry.this.identity[0].principal_id
}

output "project_id" {
  description = "AI Foundry Project resource ID"
  value       = azurerm_ai_foundry_project.this.id
}

output "ai_services_id" {
  description = "AI Services resource ID"
  value       = azurerm_ai_services.this.id
}

output "ai_services_endpoint" {
  description = "AI Services endpoint"
  value       = azurerm_ai_services.this.endpoint
}

output "ai_services_principal_id" {
  description = "AI Services system-assigned identity principal ID"
  value       = azurerm_ai_services.this.identity[0].principal_id
}

output "deployment_ids" {
  description = "Map of deployment name to deployment ID"
  value       = { for k, v in azurerm_cognitive_deployment.this : k => v.id }
}
```

- [ ] **Step 2: Validate foundry module**

```bash
cd modules/foundry && terraform init -backend=false && terraform validate && terraform fmt -check -recursive
```

- [ ] **Step 3: Commit**

```bash
git add modules/foundry/
git commit -m "feat: add foundry module with Hub, Project, AI Services, model deployments"
```

---

### Task 8: RBAC module

**Files:**
- Create: `modules/rbac/versions.tf`
- Create: `modules/rbac/variables.tf`
- Create: `modules/rbac/main.tf`
- Create: `modules/rbac/outputs.tf`

- [ ] **Step 1: Create all rbac module files**

Create `modules/rbac/versions.tf` (same pattern).

Create `modules/rbac/variables.tf`:

```hcl
variable "foundry_hub_principal_id" {
  description = "Principal ID of the Foundry Hub managed identity"
  type        = string
}

variable "ai_services_principal_id" {
  description = "Principal ID of the AI Services managed identity"
  type        = string
}

variable "storage_account_id" {
  description = "Storage account resource ID"
  type        = string
}

variable "search_service_id" {
  description = "AI Search service resource ID"
  type        = string
}

variable "key_vault_id" {
  description = "Key Vault resource ID"
  type        = string
}

variable "redis_cache_id" {
  description = "Redis cache resource ID (optional)"
  type        = string
  default     = null
}

variable "enable_redis" {
  description = "Whether Redis role assignments should be created"
  type        = bool
  default     = false
}

variable "additional_role_assignments" {
  description = "Additional custom role assignments"
  type = list(object({
    principal_id         = string
    role_definition_name = string
    scope                = string
  }))
  default = []
}
```

Create `modules/rbac/main.tf`:

```hcl
# --- Foundry Hub role assignments ---

resource "azurerm_role_assignment" "hub_storage" {
  scope                = var.storage_account_id
  role_definition_name = "Storage Blob Data Contributor"
  principal_id         = var.foundry_hub_principal_id
}

resource "azurerm_role_assignment" "hub_keyvault" {
  scope                = var.key_vault_id
  role_definition_name = "Key Vault Secrets User"
  principal_id         = var.foundry_hub_principal_id
}

resource "azurerm_role_assignment" "hub_search" {
  scope                = var.search_service_id
  role_definition_name = "Search Index Data Reader"
  principal_id         = var.foundry_hub_principal_id
}

# --- AI Services role assignments ---

resource "azurerm_role_assignment" "ai_storage" {
  scope                = var.storage_account_id
  role_definition_name = "Storage Blob Data Contributor"
  principal_id         = var.ai_services_principal_id
}

resource "azurerm_role_assignment" "ai_search_data" {
  scope                = var.search_service_id
  role_definition_name = "Search Index Data Contributor"
  principal_id         = var.ai_services_principal_id
}

resource "azurerm_role_assignment" "ai_search_service" {
  scope                = var.search_service_id
  role_definition_name = "Search Service Contributor"
  principal_id         = var.ai_services_principal_id
}

resource "azurerm_role_assignment" "ai_keyvault" {
  scope                = var.key_vault_id
  role_definition_name = "Key Vault Secrets User"
  principal_id         = var.ai_services_principal_id
}

# --- Conditional Redis role assignment ---

resource "azurerm_role_assignment" "ai_redis" {
  count = var.enable_redis ? 1 : 0

  scope                = var.redis_cache_id
  role_definition_name = "Redis Cache Contributor"
  principal_id         = var.ai_services_principal_id
}

# --- Additional custom role assignments ---

resource "azurerm_role_assignment" "additional" {
  for_each = { for idx, ra in var.additional_role_assignments : idx => ra }

  scope                = each.value.scope
  role_definition_name = each.value.role_definition_name
  principal_id         = each.value.principal_id
}
```

Create `modules/rbac/outputs.tf`:

```hcl
output "hub_role_assignment_ids" {
  description = "Hub role assignment IDs"
  value = {
    storage  = azurerm_role_assignment.hub_storage.id
    keyvault = azurerm_role_assignment.hub_keyvault.id
    search   = azurerm_role_assignment.hub_search.id
  }
}

output "ai_services_role_assignment_ids" {
  description = "AI Services role assignment IDs"
  value = merge(
    {
      storage        = azurerm_role_assignment.ai_storage.id
      search_data    = azurerm_role_assignment.ai_search_data.id
      search_service = azurerm_role_assignment.ai_search_service.id
      keyvault       = azurerm_role_assignment.ai_keyvault.id
    },
    var.enable_redis ? { redis = azurerm_role_assignment.ai_redis[0].id } : {},
  )
}
```

- [ ] **Step 2: Validate rbac module**

```bash
cd modules/rbac && terraform init -backend=false && terraform validate && terraform fmt -check -recursive
```

- [ ] **Step 3: Commit**

```bash
git add modules/rbac/
git commit -m "feat: add rbac module with Hub and AI Services cross-service role assignments"
```

---

## Chunk 5: Gateway Layer — APIM + LiteLLM

### Task 9: APIM module (optional)

**Files:**
- Create: `modules/apim/versions.tf`
- Create: `modules/apim/variables.tf`
- Create: `modules/apim/main.tf`
- Create: `modules/apim/outputs.tf`
- Create: `modules/apim/private_endpoint.tf`

- [ ] **Step 1: Create all apim module files**

Create `modules/apim/versions.tf` (same pattern).

Create `modules/apim/variables.tf`:

```hcl
variable "enable_apim" {
  description = "Whether to create APIM resources"
  type        = bool
  default     = false
}

variable "resource_group_name" {
  description = "Name of the resource group"
  type        = string
}

variable "location" {
  description = "Azure region"
  type        = string
  default     = "swedencentral"
}

variable "name_prefix" {
  description = "Prefix for resource names"
  type        = string
}

variable "enable_private_networking" {
  description = "Enable private endpoint"
  type        = bool
  default     = false
}

variable "subnet_id" {
  description = "Subnet ID for private endpoint"
  type        = string
  default     = null
}

variable "dns_zone_id" {
  description = "Private DNS zone ID for APIM"
  type        = string
  default     = null
}

variable "foundry_endpoint" {
  description = "AI Foundry endpoint URL for API backend"
  type        = string
  default     = ""
}

variable "sku_name" {
  description = "APIM SKU"
  type        = string
  default     = "Developer_1"
}

variable "publisher_name" {
  description = "APIM publisher name"
  type        = string
  default     = "AI Platform Team"
}

variable "publisher_email" {
  description = "APIM publisher email"
  type        = string
  default     = "admin@example.com"
}

variable "tags" {
  description = "Additional tags to merge with defaults"
  type        = map(string)
  default     = {}
}
```

Create `modules/apim/main.tf`:

```hcl
locals {
  default_tags = {
    SecurityControl = "Ignore"
    CostControl     = "Ignore"
  }
  tags = merge(local.default_tags, var.tags)
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
```

Create `modules/apim/private_endpoint.tf`:

```hcl
resource "azurerm_private_endpoint" "this" {
  count = var.enable_apim && var.enable_private_networking ? 1 : 0

  name                = "${var.name_prefix}-pe-apim"
  location            = var.location
  resource_group_name = var.resource_group_name
  subnet_id           = var.subnet_id
  tags                = local.tags

  private_service_connection {
    name                           = "${var.name_prefix}-psc-apim"
    private_connection_resource_id = azurerm_api_management.this[0].id
    subresource_names              = ["Gateway"]
    is_manual_connection           = false
  }

  private_dns_zone_group {
    name                 = "apim-dns"
    private_dns_zone_ids = [var.dns_zone_id]
  }
}
```

Create `modules/apim/outputs.tf`:

```hcl
output "gateway_url" {
  description = "APIM gateway URL"
  value       = var.enable_apim ? azurerm_api_management.this[0].gateway_url : null
}

output "api_id" {
  description = "Foundry API resource ID"
  value       = var.enable_apim ? azurerm_api_management_api.foundry[0].id : null
}

output "principal_id" {
  description = "APIM system-assigned identity principal ID"
  value       = var.enable_apim ? azurerm_api_management.this[0].identity[0].principal_id : null
}
```

- [ ] **Step 2: Validate apim module**

```bash
cd modules/apim && terraform init -backend=false && terraform validate && terraform fmt -check -recursive
```

- [ ] **Step 3: Commit**

```bash
git add modules/apim/
git commit -m "feat: add apim module with optional API Management, Foundry API facade"
```

---

### Task 10: LiteLLM module (optional)

**Files:**
- Create: `modules/litellm/versions.tf`
- Create: `modules/litellm/variables.tf`
- Create: `modules/litellm/main.tf`
- Create: `modules/litellm/outputs.tf`
- Create: `modules/litellm/private_endpoint.tf`

- [ ] **Step 1: Create all litellm module files**

Create `modules/litellm/versions.tf` (same pattern).

Create `modules/litellm/variables.tf`:

```hcl
variable "enable_litellm" {
  description = "Whether to create LiteLLM resources"
  type        = bool
  default     = false
}

variable "resource_group_name" {
  description = "Name of the resource group"
  type        = string
}

variable "location" {
  description = "Azure region"
  type        = string
  default     = "swedencentral"
}

variable "name_prefix" {
  description = "Prefix for resource names"
  type        = string
}

variable "enable_private_networking" {
  description = "Enable private endpoint"
  type        = bool
  default     = false
}

variable "subnet_id" {
  description = "Subnet ID for Container App environment"
  type        = string
  default     = null
}

variable "dns_zone_id" {
  description = "Private DNS zone ID for Container Apps"
  type        = string
  default     = null
}

variable "key_vault_id" {
  description = "Key Vault ID for secrets"
  type        = string
  default     = null
}

variable "foundry_endpoint" {
  description = "AI Foundry endpoint URL"
  type        = string
  default     = ""
}

variable "cpu" {
  description = "CPU cores for the container"
  type        = number
  default     = 0.5
}

variable "memory" {
  description = "Memory in Gi for the container"
  type        = string
  default     = "1Gi"
}

variable "min_replicas" {
  description = "Minimum number of replicas"
  type        = number
  default     = 1
}

variable "max_replicas" {
  description = "Maximum number of replicas"
  type        = number
  default     = 3
}

variable "tags" {
  description = "Additional tags to merge with defaults"
  type        = map(string)
  default     = {}
}
```

Create `modules/litellm/main.tf`:

```hcl
locals {
  default_tags = {
    SecurityControl = "Ignore"
    CostControl     = "Ignore"
  }
  tags = merge(local.default_tags, var.tags)
}

resource "azurerm_container_app_environment" "this" {
  count = var.enable_litellm ? 1 : 0

  name                           = "${var.name_prefix}-cae"
  location                       = var.location
  resource_group_name            = var.resource_group_name
  infrastructure_subnet_id       = var.enable_private_networking ? var.subnet_id : null
  internal_load_balancer_enabled = var.enable_private_networking

  tags = local.tags
}

resource "azurerm_container_app" "this" {
  count = var.enable_litellm ? 1 : 0

  name                         = "${var.name_prefix}-litellm"
  container_app_environment_id = azurerm_container_app_environment.this[0].id
  resource_group_name          = var.resource_group_name
  revision_mode                = "Single"
  tags                         = local.tags

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
```

Create `modules/litellm/private_endpoint.tf`:

```hcl
# Container Apps private endpoint is handled via internal_load_balancer_enabled
# on the Container App Environment. No separate azurerm_private_endpoint needed
# when the environment is deployed into a subnet with internal LB.
```

Create `modules/litellm/outputs.tf`:

```hcl
output "endpoint_url" {
  description = "LiteLLM endpoint URL"
  value       = var.enable_litellm ? azurerm_container_app.this[0].ingress[0].fqdn : null
}

output "environment_id" {
  description = "Container App Environment ID"
  value       = var.enable_litellm ? azurerm_container_app_environment.this[0].id : null
}
```

- [ ] **Step 2: Validate litellm module**

```bash
cd modules/litellm && terraform init -backend=false && terraform validate && terraform fmt -check -recursive
```

- [ ] **Step 3: Commit**

```bash
git add modules/litellm/
git commit -m "feat: add litellm module with optional Container App running LiteLLM proxy"
```

---

## Chunk 6: Examples

### Task 11: Complete example

**Files:**
- Create: `examples/complete/versions.tf`
- Create: `examples/complete/variables.tf`
- Create: `examples/complete/main.tf`
- Create: `examples/complete/outputs.tf`
- Create: `examples/complete/terraform.tfvars.example`

- [ ] **Step 1: Create complete example files**

Create `examples/complete/versions.tf`:

```hcl
terraform {
  required_version = ">= 1.5"

  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = ">= 4.0"
    }
  }
}

provider "azurerm" {
  features {}
}
```

Create `examples/complete/variables.tf`:

```hcl
variable "name_prefix" {
  description = "Prefix for all resource names"
  type        = string
  default     = "foundry"
}

variable "location" {
  description = "Azure region"
  type        = string
  default     = "swedencentral"
}

variable "enable_private_networking" {
  description = "Enable private networking for all resources"
  type        = bool
  default     = false
}

variable "enable_redis" {
  description = "Enable Redis for model caching"
  type        = bool
  default     = false
}

variable "enable_apim" {
  description = "Enable API Management"
  type        = bool
  default     = false
}

variable "enable_litellm" {
  description = "Enable LiteLLM proxy"
  type        = bool
  default     = false
}

variable "alert_email" {
  description = "Email for alert notifications"
  type        = string
  default     = null
}

variable "tags" {
  description = "Additional tags for all resources"
  type        = map(string)
  default     = {}
}
```

Create `examples/complete/main.tf`:

```hcl
resource "azurerm_resource_group" "this" {
  name     = "${var.name_prefix}-rg"
  location = var.location
  tags     = var.tags
}

# --- Networking ---

module "networking" {
  source = "../../modules/networking"

  resource_group_name       = azurerm_resource_group.this.name
  location                  = var.location
  name_prefix               = var.name_prefix
  enable_private_networking = var.enable_private_networking
  enable_redis              = var.enable_redis
  enable_apim               = var.enable_apim
  enable_litellm            = var.enable_litellm
  tags                      = var.tags
}

# --- Monitoring (early — App Insights ID needed by Foundry) ---

module "monitoring" {
  source = "../../modules/monitoring"

  resource_group_name = azurerm_resource_group.this.name
  location            = var.location
  name_prefix         = var.name_prefix
  alert_email         = var.alert_email
  enable_redis        = var.enable_redis
  tags                = var.tags

  # Note: Foundry/APIM diagnostics created separately below to avoid circular deps
  resource_ids = merge(
    {
      storage  = module.storage.storage_account_id
      search   = module.search.search_service_id
      keyvault = module.keyvault.key_vault_id
    },
    var.enable_redis ? { redis = module.redis.redis_cache_id } : {},
  )

}

# --- Data Layer ---

module "storage" {
  source = "../../modules/storage"

  resource_group_name       = azurerm_resource_group.this.name
  location                  = var.location
  name_prefix               = var.name_prefix
  enable_private_networking = var.enable_private_networking
  subnet_id                 = try(module.networking.subnet_ids["storage"], null)
  dns_zone_ids = {
    blob = try(module.networking.dns_zone_ids["blob"], "")
    dfs  = try(module.networking.dns_zone_ids["dfs"], "")
  }
  tags = var.tags
}

module "search" {
  source = "../../modules/search"

  resource_group_name       = azurerm_resource_group.this.name
  location                  = var.location
  name_prefix               = var.name_prefix
  enable_private_networking = var.enable_private_networking
  subnet_id                 = try(module.networking.subnet_ids["search"], null)
  dns_zone_id               = try(module.networking.dns_zone_ids["search"], null)
  tags                      = var.tags
}

module "redis" {
  source = "../../modules/redis"

  enable_redis              = var.enable_redis
  resource_group_name       = azurerm_resource_group.this.name
  location                  = var.location
  name_prefix               = var.name_prefix
  enable_private_networking = var.enable_private_networking
  subnet_id                 = try(module.networking.subnet_ids["redis"], null)
  dns_zone_id               = try(module.networking.dns_zone_ids["redis"], null)
  tags                      = var.tags
}

module "keyvault" {
  source = "../../modules/keyvault"

  resource_group_name       = azurerm_resource_group.this.name
  location                  = var.location
  name_prefix               = var.name_prefix
  enable_private_networking = var.enable_private_networking
  subnet_id                 = try(module.networking.subnet_ids["keyvault"], null)
  dns_zone_id               = try(module.networking.dns_zone_ids["keyvault"], null)
  tags                      = var.tags
}

# --- AI Layer ---

module "foundry" {
  source = "../../modules/foundry"

  resource_group_name       = azurerm_resource_group.this.name
  location                  = var.location
  name_prefix               = var.name_prefix
  enable_private_networking = var.enable_private_networking
  subnet_id                 = try(module.networking.subnet_ids["foundry"], null)
  dns_zone_ids = {
    cognitiveservices  = try(module.networking.dns_zone_ids["cognitiveservices"], "")
    foundry_api        = try(module.networking.dns_zone_ids["foundry_api"], "")
    foundry_notebooks  = try(module.networking.dns_zone_ids["foundry_notebooks"], "")
  }
  storage_account_id      = module.storage.storage_account_id
  key_vault_id            = module.keyvault.key_vault_id
  application_insights_id = module.monitoring.application_insights_id
  tags                    = var.tags
}

module "rbac" {
  source = "../../modules/rbac"

  foundry_hub_principal_id = module.foundry.hub_principal_id
  ai_services_principal_id = module.foundry.ai_services_principal_id
  storage_account_id       = module.storage.storage_account_id
  search_service_id        = module.search.search_service_id
  key_vault_id             = module.keyvault.key_vault_id
  redis_cache_id           = module.redis.redis_cache_id
  enable_redis             = var.enable_redis
}

# --- Diagnostic settings for resources created after monitoring ---

resource "azurerm_monitor_diagnostic_setting" "foundry" {
  name                       = "foundry-diag"
  target_resource_id         = module.foundry.ai_services_id
  log_analytics_workspace_id = module.monitoring.log_analytics_workspace_id

  enabled_log {
    category_group = "allLogs"
  }

  metric {
    category = "AllMetrics"
    enabled  = true
  }
}

# --- Gateway Layer (optional) ---

module "apim" {
  source = "../../modules/apim"

  enable_apim               = var.enable_apim
  resource_group_name       = azurerm_resource_group.this.name
  location                  = var.location
  name_prefix               = var.name_prefix
  enable_private_networking = var.enable_private_networking
  subnet_id                 = try(module.networking.subnet_ids["apim"], null)
  dns_zone_id               = try(module.networking.dns_zone_ids["apim"], null)
  foundry_endpoint          = module.foundry.ai_services_endpoint
  tags                      = var.tags
}

module "litellm" {
  source = "../../modules/litellm"

  enable_litellm            = var.enable_litellm
  resource_group_name       = azurerm_resource_group.this.name
  location                  = var.location
  name_prefix               = var.name_prefix
  enable_private_networking = var.enable_private_networking
  subnet_id                 = try(module.networking.subnet_ids["litellm"], null)
  dns_zone_id               = try(module.networking.dns_zone_ids["litellm"], null)
  key_vault_id              = module.keyvault.key_vault_id
  foundry_endpoint          = module.foundry.ai_services_endpoint
  tags                      = var.tags
}
```

Create `examples/complete/outputs.tf`:

```hcl
output "resource_group_name" {
  value = azurerm_resource_group.this.name
}

output "foundry_hub_id" {
  value = module.foundry.hub_id
}

output "foundry_project_id" {
  value = module.foundry.project_id
}

output "ai_services_endpoint" {
  value = module.foundry.ai_services_endpoint
}

output "storage_account_name" {
  value = module.storage.storage_account_name
}

output "search_endpoint" {
  value = module.search.endpoint
}

output "key_vault_uri" {
  value = module.keyvault.key_vault_uri
}

output "apim_gateway_url" {
  value = module.apim.gateway_url
}

output "litellm_endpoint" {
  value = module.litellm.endpoint_url
}
```

Create `examples/complete/terraform.tfvars.example`:

```hcl
name_prefix               = "foundry-prod"
location                  = "swedencentral"
enable_private_networking = false
enable_redis              = false
enable_apim               = false
enable_litellm            = false
alert_email               = "ops@example.com"

tags = {
  Environment = "production"
  Project     = "ai-foundry"
}
```

- [ ] **Step 2: Validate complete example**

```bash
cd examples/complete && terraform init -backend=false && terraform validate && terraform fmt -check -recursive
```

- [ ] **Step 3: Commit**

```bash
git add examples/complete/
git commit -m "feat: add complete example wiring all modules for full RAG pipeline"
```

---

### Task 12: Minimal example

**Files:**
- Create: `examples/minimal/versions.tf`
- Create: `examples/minimal/variables.tf`
- Create: `examples/minimal/main.tf`
- Create: `examples/minimal/outputs.tf`
- Create: `examples/minimal/terraform.tfvars.example`

- [ ] **Step 1: Create minimal example files**

Create `examples/minimal/versions.tf` (same as complete).

Create `examples/minimal/variables.tf`:

```hcl
variable "name_prefix" {
  description = "Prefix for all resource names"
  type        = string
  default     = "foundry"
}

variable "location" {
  description = "Azure region"
  type        = string
  default     = "swedencentral"
}

variable "enable_private_networking" {
  description = "Enable private networking for all resources"
  type        = bool
  default     = false
}

variable "tags" {
  description = "Additional tags for all resources"
  type        = map(string)
  default     = {}
}
```

Create `examples/minimal/main.tf`:

```hcl
resource "azurerm_resource_group" "this" {
  name     = "${var.name_prefix}-rg"
  location = var.location
  tags     = var.tags
}

module "networking" {
  source = "../../modules/networking"

  resource_group_name       = azurerm_resource_group.this.name
  location                  = var.location
  name_prefix               = var.name_prefix
  enable_private_networking = var.enable_private_networking
  tags                      = var.tags
}

module "monitoring" {
  source = "../../modules/monitoring"

  resource_group_name = azurerm_resource_group.this.name
  location            = var.location
  name_prefix         = var.name_prefix
  tags                = var.tags

  resource_ids = {
    storage  = module.storage.storage_account_id
    search   = module.search.search_service_id
    keyvault = module.keyvault.key_vault_id
  }

}

module "storage" {
  source = "../../modules/storage"

  resource_group_name       = azurerm_resource_group.this.name
  location                  = var.location
  name_prefix               = var.name_prefix
  enable_private_networking = var.enable_private_networking
  subnet_id                 = try(module.networking.subnet_ids["storage"], null)
  dns_zone_ids = {
    blob = try(module.networking.dns_zone_ids["blob"], "")
    dfs  = try(module.networking.dns_zone_ids["dfs"], "")
  }
  tags = var.tags
}

module "search" {
  source = "../../modules/search"

  resource_group_name       = azurerm_resource_group.this.name
  location                  = var.location
  name_prefix               = var.name_prefix
  enable_private_networking = var.enable_private_networking
  subnet_id                 = try(module.networking.subnet_ids["search"], null)
  dns_zone_id               = try(module.networking.dns_zone_ids["search"], null)
  tags                      = var.tags
}

module "keyvault" {
  source = "../../modules/keyvault"

  resource_group_name       = azurerm_resource_group.this.name
  location                  = var.location
  name_prefix               = var.name_prefix
  enable_private_networking = var.enable_private_networking
  subnet_id                 = try(module.networking.subnet_ids["keyvault"], null)
  dns_zone_id               = try(module.networking.dns_zone_ids["keyvault"], null)
  tags                      = var.tags
}

module "foundry" {
  source = "../../modules/foundry"

  resource_group_name       = azurerm_resource_group.this.name
  location                  = var.location
  name_prefix               = var.name_prefix
  enable_private_networking = var.enable_private_networking
  subnet_id                 = try(module.networking.subnet_ids["foundry"], null)
  dns_zone_ids = {
    cognitiveservices  = try(module.networking.dns_zone_ids["cognitiveservices"], "")
    foundry_api        = try(module.networking.dns_zone_ids["foundry_api"], "")
    foundry_notebooks  = try(module.networking.dns_zone_ids["foundry_notebooks"], "")
  }
  storage_account_id      = module.storage.storage_account_id
  key_vault_id            = module.keyvault.key_vault_id
  application_insights_id = module.monitoring.application_insights_id
  tags                    = var.tags
}

module "rbac" {
  source = "../../modules/rbac"

  foundry_hub_principal_id = module.foundry.hub_principal_id
  ai_services_principal_id = module.foundry.ai_services_principal_id
  storage_account_id       = module.storage.storage_account_id
  search_service_id        = module.search.search_service_id
  key_vault_id             = module.keyvault.key_vault_id
}

resource "azurerm_monitor_diagnostic_setting" "foundry" {
  name                       = "foundry-diag"
  target_resource_id         = module.foundry.ai_services_id
  log_analytics_workspace_id = module.monitoring.log_analytics_workspace_id

  enabled_log {
    category_group = "allLogs"
  }

  metric {
    category = "AllMetrics"
    enabled  = true
  }
}
```

Create `examples/minimal/outputs.tf`:

```hcl
output "resource_group_name" {
  value = azurerm_resource_group.this.name
}

output "foundry_hub_id" {
  value = module.foundry.hub_id
}

output "foundry_project_id" {
  value = module.foundry.project_id
}

output "ai_services_endpoint" {
  value = module.foundry.ai_services_endpoint
}

output "storage_account_name" {
  value = module.storage.storage_account_name
}

output "search_endpoint" {
  value = module.search.endpoint
}

output "key_vault_uri" {
  value = module.keyvault.key_vault_uri
}
```

Create `examples/minimal/terraform.tfvars.example`:

```hcl
name_prefix               = "foundry-dev"
location                  = "swedencentral"
enable_private_networking = false

tags = {
  Environment = "development"
  Project     = "ai-foundry"
}
```

- [ ] **Step 2: Validate minimal example**

```bash
cd examples/minimal && terraform init -backend=false && terraform validate && terraform fmt -check -recursive
```

- [ ] **Step 3: Commit**

```bash
git add examples/minimal/
git commit -m "feat: add minimal example with core modules only"
```

---

## Chunk 7: Validation

### Task 13: Full validation pass

- [ ] **Step 1: Format all files**

```bash
terraform fmt -recursive .
```

- [ ] **Step 2: Validate each module individually**

```bash
for dir in modules/*/; do
  echo "=== Validating $dir ==="
  cd "$dir" && terraform init -backend=false && terraform validate && cd ../..
done
```

- [ ] **Step 3: Validate each example**

```bash
for dir in examples/*/; do
  echo "=== Validating $dir ==="
  cd "$dir" && terraform init -backend=false && terraform validate && cd ../..
done
```

- [ ] **Step 4: Commit any formatting fixes**

```bash
git add -A
git commit -m "chore: terraform fmt on all modules and examples"
```

- [ ] **Step 5: Final commit — spec and plan docs**

```bash
git add docs/
git commit -m "docs: add design spec and implementation plan"
```
