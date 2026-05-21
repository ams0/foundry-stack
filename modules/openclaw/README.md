## Requirements

| Name | Version |
| ---- | ------- |
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | >= 1.9 |
| <a name="requirement_azurerm"></a> [azurerm](#requirement\_azurerm) | ~> 4.64 |
| <a name="requirement_random"></a> [random](#requirement\_random) | ~> 3.8 |

## Providers

| Name | Version |
| ---- | ------- |
| <a name="provider_azurerm"></a> [azurerm](#provider\_azurerm) | 4.73.0 |
| <a name="provider_random"></a> [random](#provider\_random) | 3.9.0 |

## Modules

No modules.

## Resources

| Name | Type |
| ---- | ---- |
| [azurerm_container_app.this](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/container_app) | resource |
| [azurerm_container_app_environment.this](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/container_app_environment) | resource |
| [random_password.gateway_token](https://registry.terraform.io/providers/hashicorp/random/latest/docs/resources/password) | resource |

## Inputs

| Name | Description | Type | Default | Required |
| ---- | ----------- | ---- | ------- | :------: |
| <a name="input_allowed_origins"></a> [allowed\_origins](#input\_allowed\_origins) | List of allowed CORS origins for the gateway | `list(string)` | <pre>[<br/>  "app://localhost"<br/>]</pre> | no |
| <a name="input_container_app_environment_id"></a> [container\_app\_environment\_id](#input\_container\_app\_environment\_id) | Existing Container App Environment ID (shared with LiteLLM) | `string` | `null` | no |
| <a name="input_cpu"></a> [cpu](#input\_cpu) | CPU cores for the container | `number` | `1` | no |
| <a name="input_create_own_environment"></a> [create\_own\_environment](#input\_create\_own\_environment) | Whether to create its own Container App Environment (false = shared with LiteLLM) | `bool` | `false` | no |
| <a name="input_enable_openclaw"></a> [enable\_openclaw](#input\_enable\_openclaw) | Whether to create OpenClaw resources | `bool` | `false` | no |
| <a name="input_enable_private_networking"></a> [enable\_private\_networking](#input\_enable\_private\_networking) | Enable private networking | `bool` | `false` | no |
| <a name="input_extra_env"></a> [extra\_env](#input\_extra\_env) | List of additional environment variables. Set sensitive=true to reference from extra\_secrets. | <pre>list(object({<br/>    name      = string<br/>    value     = string<br/>    sensitive = optional(bool, false)<br/>  }))</pre> | `[]` | no |
| <a name="input_extra_secrets"></a> [extra\_secrets](#input\_extra\_secrets) | Map of additional secrets (name => value) to inject into the container. These become available as secret references. | `map(string)` | `{}` | no |
| <a name="input_gateway_token"></a> [gateway\_token](#input\_gateway\_token) | OpenClaw gateway auth token. Auto-generated if empty. | `string` | `""` | no |
| <a name="input_image"></a> [image](#input\_image) | OpenClaw container image | `string` | `"ghcr.io/openclaw/openclaw:latest"` | no |
| <a name="input_litellm_api_key"></a> [litellm\_api\_key](#input\_litellm\_api\_key) | LiteLLM API key for authentication | `string` | `""` | no |
| <a name="input_litellm_endpoint"></a> [litellm\_endpoint](#input\_litellm\_endpoint) | LiteLLM proxy endpoint URL | `string` | n/a | yes |
| <a name="input_location"></a> [location](#input\_location) | Azure region | `string` | `"swedencentral"` | no |
| <a name="input_memory"></a> [memory](#input\_memory) | Memory for the container | `string` | `"2Gi"` | no |
| <a name="input_model_config"></a> [model\_config](#input\_model\_config) | Model configuration for OpenClaw's LiteLLM provider | <pre>list(object({<br/>    id             = string<br/>    name           = string<br/>    reasoning      = optional(bool, false)<br/>    context_window = optional(number, 128000)<br/>    max_tokens     = optional(number, 128000)<br/>  }))</pre> | <pre>[<br/>  {<br/>    "context_window": 128000,<br/>    "id": "gpt-5",<br/>    "max_tokens": 128000,<br/>    "name": "GPT-5 (Azure/LiteLLM)",<br/>    "reasoning": false<br/>  }<br/>]</pre> | no |
| <a name="input_name_prefix"></a> [name\_prefix](#input\_name\_prefix) | Prefix for resource names | `string` | n/a | yes |
| <a name="input_resource_group_name"></a> [resource\_group\_name](#input\_resource\_group\_name) | Name of the resource group | `string` | n/a | yes |
| <a name="input_subnet_id"></a> [subnet\_id](#input\_subnet\_id) | Subnet ID for Container App environment (only used if creating own environment) | `string` | `null` | no |
| <a name="input_tags"></a> [tags](#input\_tags) | Tags to apply to resources | `map(string)` | `{}` | no |

## Outputs

| Name | Description |
| ---- | ----------- |
| <a name="output_endpoint_url"></a> [endpoint\_url](#output\_endpoint\_url) | OpenClaw web UI endpoint URL |
| <a name="output_gateway_token"></a> [gateway\_token](#output\_gateway\_token) | OpenClaw gateway auth token |
| <a name="output_provider_config"></a> [provider\_config](#output\_provider\_config) | Generated OpenClaw provider configuration (JSON) |
