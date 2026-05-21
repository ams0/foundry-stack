## Requirements

| Name | Version |
| ---- | ------- |
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | >= 1.9 |
| <a name="requirement_azapi"></a> [azapi](#requirement\_azapi) | ~> 2.8 |
| <a name="requirement_azurerm"></a> [azurerm](#requirement\_azurerm) | ~> 4.64 |

## Providers

| Name | Version |
| ---- | ------- |
| <a name="provider_azapi"></a> [azapi](#provider\_azapi) | 2.9.0 |
| <a name="provider_azurerm"></a> [azurerm](#provider\_azurerm) | 4.73.0 |

## Modules

No modules.

## Resources

| Name | Type |
| ---- | ---- |
| [azapi_resource.azuremonitor_logger](https://registry.terraform.io/providers/azure/azapi/latest/docs/resources/resource) | resource |
| [azapi_resource.backend_pool](https://registry.terraform.io/providers/azure/azapi/latest/docs/resources/resource) | resource |
| [azapi_resource.content_safety_backend](https://registry.terraform.io/providers/azure/azapi/latest/docs/resources/resource) | resource |
| [azapi_resource.embeddings_backend](https://registry.terraform.io/providers/azure/azapi/latest/docs/resources/resource) | resource |
| [azapi_resource.eventhub_logger](https://registry.terraform.io/providers/azure/azapi/latest/docs/resources/resource) | resource |
| [azapi_resource.eventhub_pii_logger](https://registry.terraform.io/providers/azure/azapi/latest/docs/resources/resource) | resource |
| [azapi_resource.llm_backend](https://registry.terraform.io/providers/azure/azapi/latest/docs/resources/resource) | resource |
| [azapi_resource.ms_learn_mcp_backend](https://registry.terraform.io/providers/azure/azapi/latest/docs/resources/resource) | resource |
| [azapi_resource.openai_realtime_api](https://registry.terraform.io/providers/azure/azapi/latest/docs/resources/resource) | resource |
| [azapi_resource.openai_realtime_handshake_policy](https://registry.terraform.io/providers/azure/azapi/latest/docs/resources/resource) | resource |
| [azapi_resource.redis_cache](https://registry.terraform.io/providers/azure/azapi/latest/docs/resources/resource) | resource |
| [azurerm_api_management_api.ai_model_inference](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/api_management_api) | resource |
| [azurerm_api_management_api.ai_search_index](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/api_management_api) | resource |
| [azurerm_api_management_api.ai_search_service](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/api_management_api) | resource |
| [azurerm_api_management_api.azure_openai](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/api_management_api) | resource |
| [azurerm_api_management_api.doc_intel](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/api_management_api) | resource |
| [azurerm_api_management_api.doc_intel_legacy](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/api_management_api) | resource |
| [azurerm_api_management_api.language](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/api_management_api) | resource |
| [azurerm_api_management_api.speech](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/api_management_api) | resource |
| [azurerm_api_management_api.translator](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/api_management_api) | resource |
| [azurerm_api_management_api.unified_ai](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/api_management_api) | resource |
| [azurerm_api_management_api.universal_llm](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/api_management_api) | resource |
| [azurerm_api_management_api.weather](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/api_management_api) | resource |
| [azurerm_api_management_api_operation_policy.azure_openai_deployment_by_name](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/api_management_api_operation_policy) | resource |
| [azurerm_api_management_api_operation_policy.azure_openai_deployments](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/api_management_api_operation_policy) | resource |
| [azurerm_api_management_api_operation_policy.unified_ai_deployment_by_name](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/api_management_api_operation_policy) | resource |
| [azurerm_api_management_api_operation_policy.unified_ai_deployments](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/api_management_api_operation_policy) | resource |
| [azurerm_api_management_api_operation_policy.universal_llm_deployment_by_name](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/api_management_api_operation_policy) | resource |
| [azurerm_api_management_api_operation_policy.universal_llm_deployments](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/api_management_api_operation_policy) | resource |
| [azurerm_api_management_api_operation_policy.universal_llm_list_models](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/api_management_api_operation_policy) | resource |
| [azurerm_api_management_api_operation_policy.universal_llm_retrieve_model](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/api_management_api_operation_policy) | resource |
| [azurerm_api_management_api_policy.ai_model_inference](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/api_management_api_policy) | resource |
| [azurerm_api_management_api_policy.ai_search_index](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/api_management_api_policy) | resource |
| [azurerm_api_management_api_policy.ai_search_service](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/api_management_api_policy) | resource |
| [azurerm_api_management_api_policy.azure_openai](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/api_management_api_policy) | resource |
| [azurerm_api_management_api_policy.doc_intel](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/api_management_api_policy) | resource |
| [azurerm_api_management_api_policy.doc_intel_legacy](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/api_management_api_policy) | resource |
| [azurerm_api_management_api_policy.translator](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/api_management_api_policy) | resource |
| [azurerm_api_management_api_policy.unified_ai](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/api_management_api_policy) | resource |
| [azurerm_api_management_api_policy.universal_llm](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/api_management_api_policy) | resource |
| [azurerm_api_management_api_policy.weather](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/api_management_api_policy) | resource |
| [azurerm_api_management_diagnostic.appinsights](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/api_management_diagnostic) | resource |
| [azurerm_api_management_logger.appinsights](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/api_management_logger) | resource |
| [azurerm_api_management_named_value.this](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/api_management_named_value) | resource |
| [azurerm_api_management_policy_fragment.get_available_models](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/api_management_policy_fragment) | resource |
| [azurerm_api_management_policy_fragment.metadata_config](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/api_management_policy_fragment) | resource |
| [azurerm_api_management_policy_fragment.resolve_model_alias](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/api_management_policy_fragment) | resource |
| [azurerm_api_management_policy_fragment.set_backend_authorization](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/api_management_policy_fragment) | resource |
| [azurerm_api_management_policy_fragment.set_backend_pools](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/api_management_policy_fragment) | resource |
| [azurerm_api_management_policy_fragment.static](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/api_management_policy_fragment) | resource |
| [azurerm_api_management_product.llm_oauth](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/api_management_product) | resource |
| [azurerm_api_management_product.unified_ai](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/api_management_product) | resource |
| [azurerm_api_management_product_api.unified_ai](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/api_management_product_api) | resource |
| [azurerm_api_management_product_policy.llm_oauth](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/api_management_product_policy) | resource |
| [azurerm_api_management_product_policy.unified_ai](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/api_management_product_policy) | resource |
| [azurerm_monitor_diagnostic_setting.apim](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/monitor_diagnostic_setting) | resource |
| [azurerm_client_config.current](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/data-sources/client_config) | data source |

## Inputs

| Name | Description | Type | Default | Required |
| ---- | ----------- | ---- | ------- | :------: |
| <a name="input_ai_language_service_key"></a> [ai\_language\_service\_key](#input\_ai\_language\_service\_key) | Azure AI Language key for the piiServiceKey named value. Prefer managed identity. | `string` | `"replace-with-language-service-key-if-needed"` | no |
| <a name="input_ai_language_service_url"></a> [ai\_language\_service\_url](#input\_ai\_language\_service\_url) | Azure AI Language endpoint used by frag-pii-anonymization (piiServiceUrl named value). | `string` | `""` | no |
| <a name="input_api_management_id"></a> [api\_management\_id](#input\_api\_management\_id) | Resource ID of the APIM instance to attach to. | `string` | n/a | yes |
| <a name="input_api_management_name"></a> [api\_management\_name](#input\_api\_management\_name) | Name of the APIM instance. | `string` | n/a | yes |
| <a name="input_apim_identity_client_id"></a> [apim\_identity\_client\_id](#input\_apim\_identity\_client\_id) | Client ID of the APIM user-assigned managed identity used for backend authorization. Leave empty to omit clientId from backend credentials (system-assigned identity). | `string` | `""` | no |
| <a name="input_apim_principal_id"></a> [apim\_principal\_id](#input\_apim\_principal\_id) | Principal ID (object ID) of the APIM identity used for backend authorization. Used for outputs/diagnostics only. | `string` | `""` | no |
| <a name="input_application_insights_connection_string"></a> [application\_insights\_connection\_string](#input\_application\_insights\_connection\_string) | Application Insights connection string for the appinsights-logger. | `string` | `""` | no |
| <a name="input_application_insights_id"></a> [application\_insights\_id](#input\_application\_insights\_id) | Application Insights resource ID for the appinsights-logger. Leave empty to skip the App Insights logger. | `string` | `""` | no |
| <a name="input_configure_circuit_breaker"></a> [configure\_circuit\_breaker](#input\_configure\_circuit\_breaker) | Whether to configure the per-backend circuit breaker (5xx + 429 → 1m trip). | `bool` | `true` | no |
| <a name="input_content_safety_service_url"></a> [content\_safety\_service\_url](#input\_content\_safety\_service\_url) | Content Safety endpoint used by content-safety-backend (referenced from policies). | `string` | `""` | no |
| <a name="input_embeddings_backend_id"></a> [embeddings\_backend\_id](#input\_embeddings\_backend\_id) | Backend name for the embeddings backend. | `string` | `"foundry-embeddings"` | no |
| <a name="input_embeddings_backend_url"></a> [embeddings\_backend\_url](#input\_embeddings\_backend\_url) | URL of the embeddings backend (typically <foundry>/models/embeddings). | `string` | `""` | no |
| <a name="input_enable_ai_model_inference"></a> [enable\_ai\_model\_inference](#input\_enable\_ai\_model\_inference) | Deploy the ai-model-inference API. | `bool` | `true` | no |
| <a name="input_enable_ai_search"></a> [enable\_ai\_search](#input\_enable\_ai\_search) | Deploy the Azure AI Search index/service APIs. | `bool` | `false` | no |
| <a name="input_enable_apim_policies"></a> [enable\_apim\_policies](#input\_enable\_apim\_policies) | Master flag. When false, the module is a no-op. | `bool` | `false` | no |
| <a name="input_enable_azure_openai_api"></a> [enable\_azure\_openai\_api](#input\_enable\_azure\_openai\_api) | Deploy the azure-openai-api (AzureOpenAI flavor). | `bool` | `true` | no |
| <a name="input_enable_document_intelligence"></a> [enable\_document\_intelligence](#input\_enable\_document\_intelligence) | Deploy both Document Intelligence APIs (legacy /formrecognizer + modern /documentintelligence). | `bool` | `false` | no |
| <a name="input_enable_embeddings_backend"></a> [enable\_embeddings\_backend](#input\_enable\_embeddings\_backend) | Create a dedicated embeddings backend (MI auth, targets a /models/embeddings endpoint). | `bool` | `false` | no |
| <a name="input_enable_jwt_auth"></a> [enable\_jwt\_auth](#input\_enable\_jwt\_auth) | Populate the JWT named values used by frag-security-handler. When false, JWT named values are written as 'not-configured'. | `bool` | `false` | no |
| <a name="input_enable_language"></a> [enable\_language](#input\_enable\_language) | Deploy the Language API. | `bool` | `false` | no |
| <a name="input_enable_mcp_samples"></a> [enable\_mcp\_samples](#input\_enable\_mcp\_samples) | Deploy the MCP sample APIs (weather + Microsoft Learn MCP). Off by default — dev only. | `bool` | `false` | no |
| <a name="input_enable_openai_realtime"></a> [enable\_openai\_realtime](#input\_enable\_openai\_realtime) | Deploy the WebSocket openai-realtime-ws-api. | `bool` | `false` | no |
| <a name="input_enable_pii_anonymization"></a> [enable\_pii\_anonymization](#input\_enable\_pii\_anonymization) | Create the PII anonymization/deanonymization fragments + state-saving fragment + AI Foundry compatibility fragment. | `bool` | `true` | no |
| <a name="input_enable_redis_cache"></a> [enable\_redis\_cache](#input\_enable\_redis\_cache) | Register an APIM external Redis cache (referenced by semantic-cache policies). | `bool` | `false` | no |
| <a name="input_enable_speech"></a> [enable\_speech](#input\_enable\_speech) | Deploy the Speech API. | `bool` | `false` | no |
| <a name="input_enable_translator"></a> [enable\_translator](#input\_enable\_translator) | Deploy the Translator API. | `bool` | `false` | no |
| <a name="input_enable_unified_ai_api"></a> [enable\_unified\_ai\_api](#input\_enable\_unified\_ai\_api) | Deploy the unified-ai wildcard API + product + deployment operations. | `bool` | `true` | no |
| <a name="input_enable_universal_llm_api"></a> [enable\_universal\_llm\_api](#input\_enable\_universal\_llm\_api) | Deploy the universal-llm-api (OpenAIV1 flavor). | `bool` | `true` | no |
| <a name="input_entra_audience"></a> [entra\_audience](#input\_entra\_audience) | Audience value for Entra auth. | `string` | `"https://cognitiveservices.azure.com/.default"` | no |
| <a name="input_entra_auth"></a> [entra\_auth](#input\_entra\_auth) | Toggle the 'entra-auth' named value. When true, APIs are deployed with subscription\_required=false. | `bool` | `false` | no |
| <a name="input_entra_client_id"></a> [entra\_client\_id](#input\_entra\_client\_id) | Entra app registration client ID for the gateway. | `string` | `""` | no |
| <a name="input_entra_tenant_id"></a> [entra\_tenant\_id](#input\_entra\_tenant\_id) | Tenant ID for Entra auth (defaults to current subscription tenant). | `string` | `""` | no |
| <a name="input_event_hub_logger_endpoint"></a> [event\_hub\_logger\_endpoint](#input\_event\_hub\_logger\_endpoint) | Event Hub namespace endpoint (e.g. https://<ns>.servicebus.windows.net) for the usage-eventhub-logger. | `string` | `""` | no |
| <a name="input_event_hub_logger_name"></a> [event\_hub\_logger\_name](#input\_event\_hub\_logger\_name) | Event Hub name for the usage-eventhub-logger. Empty disables the EH logger. | `string` | `""` | no |
| <a name="input_event_hub_pii_logger_endpoint"></a> [event\_hub\_pii\_logger\_endpoint](#input\_event\_hub\_pii\_logger\_endpoint) | Event Hub namespace endpoint for the pii-usage-eventhub-logger. | `string` | `""` | no |
| <a name="input_event_hub_pii_logger_name"></a> [event\_hub\_pii\_logger\_name](#input\_event\_hub\_pii\_logger\_name) | Event Hub name for the pii-usage-eventhub-logger. | `string` | `""` | no |
| <a name="input_jwt_app_registration_id"></a> [jwt\_app\_registration\_id](#input\_jwt\_app\_registration\_id) | JWT app registration client ID. | `string` | `""` | no |
| <a name="input_jwt_tenant_id"></a> [jwt\_tenant\_id](#input\_jwt\_tenant\_id) | JWT tenant ID. Falls back to entra\_tenant\_id. | `string` | `""` | no |
| <a name="input_llm_backends"></a> [llm\_backends](#input\_llm\_backends) | List of LLM backends to register in APIM. One azapi backend is created per entry,<br/>and backend pools are created automatically for any model name supported by 2+ backends.<br/>Backend auth is managed identity only.<br/><br/>Each entry:<br/>  backend\_id        = unique APIM backend name<br/>  backend\_type      = "ai-foundry" \| "azure-openai" \| "external"<br/>  endpoint          = base URL of the LLM endpoint<br/>  supported\_models  = list of model entries: { name, sku?, capacity?, model\_format?, model\_version?, retirement\_date?, api\_version?, timeout?, inference\_api\_version? }<br/>  priority          = optional pool priority (default 1)<br/>  weight            = optional pool weight (default 100) | <pre>list(object({<br/>    backend_id   = string<br/>    backend_type = string<br/>    endpoint     = string<br/>    supported_models = list(object({<br/>      name                  = string<br/>      sku                   = optional(string, "Standard")<br/>      capacity              = optional(number, 100)<br/>      model_format          = optional(string, "OpenAI")<br/>      model_version         = optional(string, "1")<br/>      retirement_date       = optional(string, "")<br/>      api_version           = optional(string, "2024-02-15-preview")<br/>      timeout               = optional(number, 120)<br/>      inference_api_version = optional(string, "")<br/>    }))<br/>    priority = optional(number, 1)<br/>    weight   = optional(number, 100)<br/>  }))</pre> | `[]` | no |
| <a name="input_log_analytics_workspace_id"></a> [log\_analytics\_workspace\_id](#input\_log\_analytics\_workspace\_id) | Log Analytics workspace ID for APIM service-level diagnostic settings. Empty to skip. | `string` | `""` | no |
| <a name="input_redis_cache_connection_string"></a> [redis\_cache\_connection\_string](#input\_redis\_cache\_connection\_string) | Redis connection string for the APIM external cache. | `string` | `""` | no |
| <a name="input_redis_cache_name"></a> [redis\_cache\_name](#input\_redis\_cache\_name) | APIM cache entity name. | `string` | `"redis-cache"` | no |
| <a name="input_resource_group_name"></a> [resource\_group\_name](#input\_resource\_group\_name) | Resource group containing the APIM instance. | `string` | n/a | yes |

## Outputs

| Name | Description |
| ---- | ----------- |
| <a name="output_ai_model_inference_api_id"></a> [ai\_model\_inference\_api\_id](#output\_ai\_model\_inference\_api\_id) | Resource ID of the ai-model-inference API (empty when disabled). |
| <a name="output_azure_openai_api_id"></a> [azure\_openai\_api\_id](#output\_azure\_openai\_api\_id) | Resource ID of the azure-openai-api (empty when disabled). |
| <a name="output_backend_ids"></a> [backend\_ids](#output\_backend\_ids) | Map of backend\_id → APIM backend resource ID. |
| <a name="output_backend_pool_ids"></a> [backend\_pool\_ids](#output\_backend\_pool\_ids) | Map of pool\_name → APIM backend pool resource ID. |
| <a name="output_fragment_ids"></a> [fragment\_ids](#output\_fragment\_ids) | Map of fragment\_name → APIM policy-fragment resource ID. |
| <a name="output_unified_ai_api_id"></a> [unified\_ai\_api\_id](#output\_unified\_ai\_api\_id) | Resource ID of the unified-ai wildcard API (empty when disabled). |
| <a name="output_unified_ai_product_id"></a> [unified\_ai\_product\_id](#output\_unified\_ai\_product\_id) | Resource ID of the unified-ai product (empty when disabled). |
| <a name="output_universal_llm_api_id"></a> [universal\_llm\_api\_id](#output\_universal\_llm\_api\_id) | Resource ID of the universal-llm-api (empty when disabled). |
