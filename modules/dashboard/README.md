## Requirements

| Name | Version |
| ---- | ------- |
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | >= 1.9 |
| <a name="requirement_azurerm"></a> [azurerm](#requirement\_azurerm) | ~> 4.64 |

## Providers

| Name | Version |
| ---- | ------- |
| <a name="provider_azurerm"></a> [azurerm](#provider\_azurerm) | 4.73.0 |

## Modules

No modules.

## Resources

| Name | Type |
| ---- | ---- |
| [azurerm_portal_dashboard.this](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/portal_dashboard) | resource |

## Inputs

| Name | Description | Type | Default | Required |
| ---- | ----------- | ---- | ------- | :------: |
| <a name="input_ai_services_resource_id"></a> [ai\_services\_resource\_id](#input\_ai\_services\_resource\_id) | AI Services resource ID for metrics | `string` | n/a | yes |
| <a name="input_litellm_container_app_name"></a> [litellm\_container\_app\_name](#input\_litellm\_container\_app\_name) | LiteLLM Container App name for KQL filtering | `string` | n/a | yes |
| <a name="input_location"></a> [location](#input\_location) | Azure region | `string` | `"swedencentral"` | no |
| <a name="input_log_analytics_workspace_id"></a> [log\_analytics\_workspace\_id](#input\_log\_analytics\_workspace\_id) | Log Analytics workspace resource ID | `string` | n/a | yes |
| <a name="input_log_analytics_workspace_name"></a> [log\_analytics\_workspace\_name](#input\_log\_analytics\_workspace\_name) | Log Analytics workspace name | `string` | n/a | yes |
| <a name="input_name_prefix"></a> [name\_prefix](#input\_name\_prefix) | Prefix for resource names | `string` | n/a | yes |
| <a name="input_openclaw_container_app_name"></a> [openclaw\_container\_app\_name](#input\_openclaw\_container\_app\_name) | OpenClaw Container App name for KQL filtering | `string` | `""` | no |
| <a name="input_redis_cache_resource_id"></a> [redis\_cache\_resource\_id](#input\_redis\_cache\_resource\_id) | Redis Cache resource ID for metrics (optional) | `string` | `null` | no |
| <a name="input_resource_group_name"></a> [resource\_group\_name](#input\_resource\_group\_name) | Name of the resource group | `string` | n/a | yes |
| <a name="input_search_service_resource_id"></a> [search\_service\_resource\_id](#input\_search\_service\_resource\_id) | AI Search resource ID for metrics | `string` | n/a | yes |
| <a name="input_storage_account_resource_id"></a> [storage\_account\_resource\_id](#input\_storage\_account\_resource\_id) | Storage Account resource ID for metrics | `string` | n/a | yes |
| <a name="input_subscription_id"></a> [subscription\_id](#input\_subscription\_id) | Azure subscription ID | `string` | n/a | yes |
| <a name="input_tags"></a> [tags](#input\_tags) | Tags to apply to resources | `map(string)` | `{}` | no |

## Outputs

| Name | Description |
| ---- | ----------- |
| <a name="output_dashboard_id"></a> [dashboard\_id](#output\_dashboard\_id) | Azure Portal Dashboard resource ID |
| <a name="output_dashboard_url"></a> [dashboard\_url](#output\_dashboard\_url) | Direct URL to open the dashboard in Azure Portal |
