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
| [random_password.litellm_master_key](https://registry.terraform.io/providers/hashicorp/random/latest/docs/resources/password) | resource |

## Inputs

| Name | Description | Type | Default | Required |
| ---- | ----------- | ---- | ------- | :------: |
| <a name="input_api_version"></a> [api\_version](#input\_api\_version) | Azure OpenAI API version | `string` | `"2024-12-01-preview"` | no |
| <a name="input_cpu"></a> [cpu](#input\_cpu) | CPU cores for the container | `number` | `0.5` | no |
| <a name="input_dns_zone_id"></a> [dns\_zone\_id](#input\_dns\_zone\_id) | Private DNS zone ID for Container Apps | `string` | `null` | no |
| <a name="input_enable_litellm"></a> [enable\_litellm](#input\_enable\_litellm) | Whether to create LiteLLM resources | `bool` | `false` | no |
| <a name="input_enable_private_networking"></a> [enable\_private\_networking](#input\_enable\_private\_networking) | Enable private endpoint | `bool` | `false` | no |
| <a name="input_foundry_endpoint"></a> [foundry\_endpoint](#input\_foundry\_endpoint) | AI Foundry endpoint URL (e.g. https://<name>.cognitiveservices.azure.com/) | `string` | `""` | no |
| <a name="input_location"></a> [location](#input\_location) | Azure region | `string` | `"swedencentral"` | no |
| <a name="input_log_analytics_workspace_id"></a> [log\_analytics\_workspace\_id](#input\_log\_analytics\_workspace\_id) | Log Analytics workspace ID to send Container App logs to | `string` | `null` | no |
| <a name="input_master_key"></a> [master\_key](#input\_master\_key) | LiteLLM master API key for proxy authentication. Auto-generated if empty. | `string` | `""` | no |
| <a name="input_max_replicas"></a> [max\_replicas](#input\_max\_replicas) | Maximum number of replicas | `number` | `3` | no |
| <a name="input_memory"></a> [memory](#input\_memory) | Memory in Gi for the container | `string` | `"1Gi"` | no |
| <a name="input_min_replicas"></a> [min\_replicas](#input\_min\_replicas) | Minimum number of replicas | `number` | `1` | no |
| <a name="input_model_deployments"></a> [model\_deployments](#input\_model\_deployments) | List of Azure model deployments to expose via LiteLLM | <pre>list(object({<br/>    model_name      = string<br/>    deployment_name = string<br/>  }))</pre> | <pre>[<br/>  {<br/>    "deployment_name": "gpt-5",<br/>    "model_name": "gpt-5"<br/>  },<br/>  {<br/>    "deployment_name": "text-embedding-3-large",<br/>    "model_name": "text-embedding-3-large"<br/>  }<br/>]</pre> | no |
| <a name="input_name_prefix"></a> [name\_prefix](#input\_name\_prefix) | Prefix for resource names | `string` | n/a | yes |
| <a name="input_resource_group_name"></a> [resource\_group\_name](#input\_resource\_group\_name) | Name of the resource group | `string` | n/a | yes |
| <a name="input_subnet_id"></a> [subnet\_id](#input\_subnet\_id) | Subnet ID for Container App environment | `string` | `null` | no |
| <a name="input_tags"></a> [tags](#input\_tags) | Additional tags to merge with defaults | `map(string)` | `{}` | no |

## Outputs

| Name | Description |
| ---- | ----------- |
| <a name="output_endpoint_url"></a> [endpoint\_url](#output\_endpoint\_url) | LiteLLM endpoint URL |
| <a name="output_environment_id"></a> [environment\_id](#output\_environment\_id) | Container App Environment ID |
| <a name="output_master_key"></a> [master\_key](#output\_master\_key) | LiteLLM master API key for proxy authentication |
| <a name="output_principal_id"></a> [principal\_id](#output\_principal\_id) | LiteLLM Container App system-assigned identity principal ID |
