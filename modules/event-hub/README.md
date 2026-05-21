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
| [azurerm_eventhub.pii](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/eventhub) | resource |
| [azurerm_eventhub.usage](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/eventhub) | resource |
| [azurerm_eventhub_namespace.this](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/eventhub_namespace) | resource |
| [azurerm_monitor_diagnostic_setting.this](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/monitor_diagnostic_setting) | resource |
| [azurerm_private_endpoint.this](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/private_endpoint) | resource |

## Inputs

| Name | Description | Type | Default | Required |
| ---- | ----------- | ---- | ------- | :------: |
| <a name="input_allowed_ips"></a> [allowed\_ips](#input\_allowed\_ips) | List of IP addresses allowed to access the namespace when public access is enabled. | `list(string)` | `[]` | no |
| <a name="input_auto_inflate_enabled"></a> [auto\_inflate\_enabled](#input\_auto\_inflate\_enabled) | Enable auto-inflate (Standard only). Ignored for Basic/Premium. | `bool` | `false` | no |
| <a name="input_capacity"></a> [capacity](#input\_capacity) | Throughput units (TUs for Standard/Basic, PUs for Premium). | `number` | `1` | no |
| <a name="input_dns_zone_id"></a> [dns\_zone\_id](#input\_dns\_zone\_id) | Private DNS zone resource ID for privatelink.servicebus.windows.net. | `string` | `null` | no |
| <a name="input_enable_event_hub"></a> [enable\_event\_hub](#input\_enable\_event\_hub) | Master flag. When false, the module is a no-op. | `bool` | `false` | no |
| <a name="input_enable_private_networking"></a> [enable\_private\_networking](#input\_enable\_private\_networking) | When true, disable public network access and create a private endpoint. | `bool` | `false` | no |
| <a name="input_location"></a> [location](#input\_location) | Azure region. | `string` | n/a | yes |
| <a name="input_log_analytics_workspace_id"></a> [log\_analytics\_workspace\_id](#input\_log\_analytics\_workspace\_id) | Log Analytics workspace ID for namespace diagnostics. Empty to skip. | `string` | `""` | no |
| <a name="input_maximum_throughput_units"></a> [maximum\_throughput\_units](#input\_maximum\_throughput\_units) | Maximum TUs when auto-inflate is enabled. | `number` | `5` | no |
| <a name="input_message_retention"></a> [message\_retention](#input\_message\_retention) | Message retention in days for each hub. | `number` | `1` | no |
| <a name="input_name_prefix"></a> [name\_prefix](#input\_name\_prefix) | Prefix for resource names. | `string` | n/a | yes |
| <a name="input_partition_count"></a> [partition\_count](#input\_partition\_count) | Partition count for each hub. | `number` | `4` | no |
| <a name="input_pii_hub_name"></a> [pii\_hub\_name](#input\_pii\_hub\_name) | Name of the PII usage event hub (consumed by APIM's pii-usage-eventhub-logger). | `string` | `"pii-usage"` | no |
| <a name="input_resource_group_name"></a> [resource\_group\_name](#input\_resource\_group\_name) | Resource group to create the namespace in. | `string` | n/a | yes |
| <a name="input_sku"></a> [sku](#input\_sku) | Event Hubs SKU (Basic / Standard / Premium). | `string` | `"Standard"` | no |
| <a name="input_subnet_id"></a> [subnet\_id](#input\_subnet\_id) | Subnet ID for the private endpoint (required when enable\_private\_networking = true). | `string` | `null` | no |
| <a name="input_tags"></a> [tags](#input\_tags) | Tags to apply to the namespace and hubs. | `map(string)` | `{}` | no |
| <a name="input_usage_hub_name"></a> [usage\_hub\_name](#input\_usage\_hub\_name) | Name of the usage event hub (consumed by APIM's usage-eventhub-logger). | `string` | `"usage"` | no |

## Outputs

| Name | Description |
| ---- | ----------- |
| <a name="output_namespace_endpoint"></a> [namespace\_endpoint](#output\_namespace\_endpoint) | Event Hubs namespace endpoint (https://<namespace>.servicebus.windows.net). |
| <a name="output_namespace_fqdn"></a> [namespace\_fqdn](#output\_namespace\_fqdn) | Event Hubs namespace FQDN without scheme (<namespace>.servicebus.windows.net). |
| <a name="output_namespace_id"></a> [namespace\_id](#output\_namespace\_id) | Event Hubs namespace resource ID. |
| <a name="output_namespace_name"></a> [namespace\_name](#output\_namespace\_name) | Event Hubs namespace name. |
| <a name="output_pii_hub_name"></a> [pii\_hub\_name](#output\_pii\_hub\_name) | Name of the PII usage event hub. |
| <a name="output_usage_hub_name"></a> [usage\_hub\_name](#output\_usage\_hub\_name) | Name of the usage event hub. |
