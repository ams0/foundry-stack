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
| [azapi_resource.ai_services](https://registry.terraform.io/providers/azure/azapi/latest/docs/resources/resource) | resource |
| [azapi_resource.redis_connection](https://registry.terraform.io/providers/azure/azapi/latest/docs/resources/resource) | resource |
| [azurerm_ai_foundry.this](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/ai_foundry) | resource |
| [azurerm_ai_foundry_project.this](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/ai_foundry_project) | resource |
| [azurerm_cognitive_account_project.this](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/cognitive_account_project) | resource |
| [azurerm_cognitive_deployment.this](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/cognitive_deployment) | resource |
| [azurerm_private_endpoint.ai_services](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/private_endpoint) | resource |
| [azurerm_private_endpoint.hub](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/private_endpoint) | resource |
| [azurerm_resource_policy_exemption.hub_public_access](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/resource_policy_exemption) | resource |
| [azapi_resource_action.ai_services_keys](https://registry.terraform.io/providers/azure/azapi/latest/docs/data-sources/resource_action) | data source |
| [azurerm_client_config.current](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/data-sources/client_config) | data source |

## Inputs

| Name | Description | Type | Default | Required |
| ---- | ----------- | ---- | ------- | :------: |
| <a name="input_allowed_ips"></a> [allowed\_ips](#input\_allowed\_ips) | List of IP addresses allowed to access AI Services when not using private networking (e.g. ["95.99.46.198"]) | `list(string)` | `[]` | no |
| <a name="input_application_insights_id"></a> [application\_insights\_id](#input\_application\_insights\_id) | Application Insights ID to link to Hub | `string` | `null` | no |
| <a name="input_dns_zone_ids"></a> [dns\_zone\_ids](#input\_dns\_zone\_ids) | Map of DNS zone IDs: keys 'cognitiveservices', 'foundry\_api', 'foundry\_notebooks' | `map(string)` | `{}` | no |
| <a name="input_enable_private_networking"></a> [enable\_private\_networking](#input\_enable\_private\_networking) | Enable private endpoints | `bool` | `false` | no |
| <a name="input_enable_redis"></a> [enable\_redis](#input\_enable\_redis) | Whether to create Redis connection on the Hub | `bool` | `false` | no |
| <a name="input_existing_identity_id"></a> [existing\_identity\_id](#input\_existing\_identity\_id) | Existing user-assigned identity ID (optional, overrides system-assigned) | `string` | `null` | no |
| <a name="input_key_vault_id"></a> [key\_vault\_id](#input\_key\_vault\_id) | Key Vault ID to link to Hub | `string` | n/a | yes |
| <a name="input_location"></a> [location](#input\_location) | Azure region | `string` | `"swedencentral"` | no |
| <a name="input_model_deployments"></a> [model\_deployments](#input\_model\_deployments) | List of model deployments to create | <pre>list(object({<br/>    name          = string<br/>    model_name    = string<br/>    model_format  = optional(string, "OpenAI")<br/>    model_version = string<br/>    sku_name      = optional(string, "GlobalStandard")<br/>    sku_capacity  = optional(number, 10)<br/>  }))</pre> | <pre>[<br/>  {<br/>    "model_format": "OpenAI",<br/>    "model_name": "gpt-5",<br/>    "model_version": "2025-08-07",<br/>    "name": "gpt-5"<br/>  },<br/>  {<br/>    "model_format": "OpenAI",<br/>    "model_name": "text-embedding-3-large",<br/>    "model_version": "1",<br/>    "name": "text-embedding-3-large"<br/>  },<br/>  {<br/>    "model_format": "OpenAI",<br/>    "model_name": "gpt-realtime-1.5",<br/>    "model_version": "2026-02-23",<br/>    "name": "gpt-realtime-1-5"<br/>  },<br/>  {<br/>    "model_format": "OpenAI",<br/>    "model_name": "gpt-audio-1.5",<br/>    "model_version": "2026-02-23",<br/>    "name": "gpt-audio-1-5"<br/>  }<br/>]</pre> | no |
| <a name="input_name_prefix"></a> [name\_prefix](#input\_name\_prefix) | Prefix for resource names | `string` | n/a | yes |
| <a name="input_policy_exemption_policy_assignment_id"></a> [policy\_exemption\_policy\_assignment\_id](#input\_policy\_exemption\_policy\_assignment\_id) | Policy assignment ID to exempt the Hub from (for management group policies that force publicNetworkAccess=Disabled). Leave empty to skip. | `string` | `""` | no |
| <a name="input_redis_cache_hostname"></a> [redis\_cache\_hostname](#input\_redis\_cache\_hostname) | Redis cache hostname for Foundry Hub connection (optional) | `string` | `null` | no |
| <a name="input_redis_cache_primary_key"></a> [redis\_cache\_primary\_key](#input\_redis\_cache\_primary\_key) | Redis cache primary access key | `string` | `null` | no |
| <a name="input_redis_cache_ssl_port"></a> [redis\_cache\_ssl\_port](#input\_redis\_cache\_ssl\_port) | Redis cache SSL port | `number` | `6380` | no |
| <a name="input_resource_group_name"></a> [resource\_group\_name](#input\_resource\_group\_name) | Name of the resource group | `string` | n/a | yes |
| <a name="input_storage_account_id"></a> [storage\_account\_id](#input\_storage\_account\_id) | Storage account ID to link to Hub | `string` | n/a | yes |
| <a name="input_subnet_id"></a> [subnet\_id](#input\_subnet\_id) | Subnet ID for private endpoints | `string` | `null` | no |
| <a name="input_tags"></a> [tags](#input\_tags) | Additional tags to merge with defaults | `map(string)` | `{}` | no |

## Outputs

| Name | Description |
| ---- | ----------- |
| <a name="output_ai_services_endpoint"></a> [ai\_services\_endpoint](#output\_ai\_services\_endpoint) | AI Services endpoint |
| <a name="output_ai_services_id"></a> [ai\_services\_id](#output\_ai\_services\_id) | AI Services resource ID |
| <a name="output_ai_services_primary_key"></a> [ai\_services\_primary\_key](#output\_ai\_services\_primary\_key) | AI Services primary API key |
| <a name="output_ai_services_principal_id"></a> [ai\_services\_principal\_id](#output\_ai\_services\_principal\_id) | AI Services system-assigned identity principal ID |
| <a name="output_deployment_ids"></a> [deployment\_ids](#output\_deployment\_ids) | Map of deployment name to deployment ID |
| <a name="output_foundry_project_endpoints"></a> [foundry\_project\_endpoints](#output\_foundry\_project\_endpoints) | Cognitive Account Project endpoints |
| <a name="output_foundry_project_id"></a> [foundry\_project\_id](#output\_foundry\_project\_id) | Cognitive Account Project resource ID (new Foundry portal) |
| <a name="output_hub_id"></a> [hub\_id](#output\_hub\_id) | AI Foundry Hub resource ID |
| <a name="output_hub_principal_id"></a> [hub\_principal\_id](#output\_hub\_principal\_id) | AI Foundry Hub system-assigned identity principal ID |
| <a name="output_portal_url"></a> [portal\_url](#output\_portal\_url) | Azure AI Foundry portal URL for the project |
| <a name="output_project_id"></a> [project\_id](#output\_project\_id) | AI Foundry Project resource ID (legacy portal) |
