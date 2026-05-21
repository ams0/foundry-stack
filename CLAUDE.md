# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## What this repo is

A composable Terraform module suite for deploying Azure AI Foundry (Hub + projects + model deployments) and its surrounding platform on Azure. There is no application code — everything is HCL.

## Common commands

The repo is driven by a top-level `Makefile`. All apply/plan/destroy commands operate against an example stack, selected via the `EXAMPLE` variable (`complete` or `minimal`, default `complete`).

```sh
make init                       # terraform init for the selected example
make plan                       # terraform plan
make apply                      # terraform apply
make destroy                    # terraform destroy
make init EXAMPLE=minimal       # switch example
make validate                   # init -backend=false + validate for every module and example
make fmt                        # terraform fmt -recursive .
make fmt-check                  # check formatting without modifying
make docs                       # regenerate per-module README.md via terraform-docs
make clean                      # remove .terraform dirs and lock files
```

Targeting a single module/resource uses standard Terraform flags from the example dir, e.g. `cd examples/complete && terraform plan -target=module.foundry`. There is no test framework — `make validate` is the substitute for a unit-test run.

## Architecture

### Two-layer layout

- `modules/` — leaf modules, each owning a single Azure concern. Each module follows the same file convention: `main.tf`, `variables.tf`, `outputs.tf`, `versions.tf`, plus optional `private_endpoint.tf` and a generated `README.md`.
- `examples/` — root modules that wire the leaves together. `minimal` is the smallest viable Foundry stack; `complete` is the production-shaped reference deployment with every optional component.

Every leaf module is intended to be consumed standalone *or* through an example — do not introduce cross-module dependencies inside `modules/`; wiring belongs in the example layer.

### Logical layers (as composed in `examples/complete/main.tf`)

1. **Networking** (`networking`) — VNet, per-service subnets, private DNS zones. Returns `subnet_ids` and `dns_zone_ids` maps keyed by service name; downstream modules look up their own key with `try(... , null)` so the wiring stays uniform whether private networking is on or off.
2. **Monitoring** (`monitoring`) — Log Analytics workspace + Application Insights. Receives `resource_ids` of the resources it should auto-attach diagnostic settings to. Foundry diagnostics are intentionally attached at the example level (not inside `monitoring`) to break a circular dep.
3. **Data layer** — `storage`, `search`, `keyvault`, `redis`, `cosmosdb`. Storage and Key Vault are required by Foundry; the rest are optional via `enable_*` flags.
4. **AI layer** — `foundry` creates the AI Services account (via `azapi_resource` because `azurerm_ai_services` lacks `allowProjectManagement`), the Foundry Hub, project, and model deployments. `rbac` grants the Hub's and AI Services' managed identities the roles they need over storage/search/keyvault/redis.
5. **Gateway layer (optional)** — `apim` (API Management in front of Foundry), `litellm` (Container Apps LLM proxy with managed identity → `Cognitive Services OpenAI User` on Foundry), `openclaw` (coding-agent Container App that talks to LiteLLM and reuses its Container App Environment when `enable_litellm = true`).
6. **Dashboard** (`dashboard`) — Azure Portal dashboard that surfaces the deployed resources.

### Conventions to follow when adding/changing modules

- **Optional modules use a top-level `enable_<name>` bool input**, then gate everything inside with `count = var.enable_<name> ? 1 : 0`. The module should still return a usable shape (often `null`s) when disabled — examples wire outputs unconditionally.
- **Private networking is a single `enable_private_networking` bool** that flips `publicNetworkAccess`, `defaultAction`, and whether private endpoints are created. When disabled, `allowed_ips` is used to scope public access; when enabled, the IP allowlist is intentionally ignored.
- **Resource naming**: every name is built from `var.name_prefix` (the example layer composes this as `"<prefix>-<random_string suffix>"` so reruns are stable but multi-deploys don't collide). Don't introduce ad-hoc naming inside leaf modules.
- **Tagging**: examples inject `SecurityControl = "Ignore"` and `CostControl = "Ignore"` defaults and merge with `var.tags`. Modules accept `tags` and pass through.
- **Policy exemptions**: `foundry` accepts a `policy_exemption_policy_assignment_id` to exempt the Hub from management-group policies that force `publicNetworkAccess=Disabled`. This is the seam for environments where org policy conflicts with module-level network settings.
- **Provider note**: Foundry uses both `azurerm` and `azapi`. Reach for `azapi` only when `azurerm` lacks the property (the AI Services `allowProjectManagement` flag is the established precedent).

### Cost estimation

`examples/complete/main.tf` carries a `local.estimated_costs` map (Sweden Central, base infrastructure only). Toggling `enable_*` flags is reflected in the `estimated_monthly_cost` output. Update the map whenever a new optional module is added.

## Things not to do

- Don't add `terraform.tfstate*` to commits — local state files appear in `examples/complete/` during development and are environment-specific.
- Don't hand-edit per-module `README.md` — they're generated by `make docs` (terraform-docs).
- Don't add cross-module `source = "../<other-module>"` references inside `modules/` — keep that composition in `examples/`.
