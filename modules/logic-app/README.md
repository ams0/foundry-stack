## Requirements

| Name | Version |
| ---- | ------- |
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | >= 1.9 |
| <a name="requirement_archive"></a> [archive](#requirement\_archive) | ~> 2.5 |
| <a name="requirement_azurerm"></a> [azurerm](#requirement\_azurerm) | ~> 4.64 |
| <a name="requirement_random"></a> [random](#requirement\_random) | ~> 3.8 |

## Providers

| Name | Version |
| ---- | ------- |
| <a name="provider_archive"></a> [archive](#provider\_archive) | 2.8.0 |
| <a name="provider_azurerm"></a> [azurerm](#provider\_azurerm) | 4.73.0 |
| <a name="provider_random"></a> [random](#provider\_random) | 3.9.0 |

## Modules

No modules.

## Resources

| Name | Type |
| ---- | ---- |
| [azurerm_logic_app_standard.this](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/logic_app_standard) | resource |
| [azurerm_monitor_diagnostic_setting.this](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/monitor_diagnostic_setting) | resource |
| [azurerm_service_plan.this](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/service_plan) | resource |
| [azurerm_storage_account.runtime](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/storage_account) | resource |
| [azurerm_storage_blob.workflows](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/storage_blob) | resource |
| [azurerm_storage_container.packages](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/storage_container) | resource |
| [random_string.suffix](https://registry.terraform.io/providers/hashicorp/random/latest/docs/resources/string) | resource |
| [archive_file.workflows](https://registry.terraform.io/providers/hashicorp/archive/latest/docs/data-sources/file) | data source |
| [azurerm_client_config.current](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/data-sources/client_config) | data source |
| [azurerm_storage_account_blob_container_sas.workflows](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/data-sources/storage_account_blob_container_sas) | data source |

## Inputs

| Name | Description | Type | Default | Required |
| ---- | ----------- | ---- | ------- | :------: |
| <a name="input_application_insights_connection_string"></a> [application\_insights\_connection\_string](#input\_application\_insights\_connection\_string) | App Insights connection string for the Logic App's own telemetry. | `string` | `""` | no |
| <a name="input_application_insights_name"></a> [application\_insights\_name](#input\_application\_insights\_name) | Application Insights resource name (used by scheduled KQL queries). | `string` | n/a | yes |
| <a name="input_application_insights_resource_group"></a> [application\_insights\_resource\_group](#input\_application\_insights\_resource\_group) | Resource group of the Application Insights instance. | `string` | n/a | yes |
| <a name="input_application_insights_subscription_id"></a> [application\_insights\_subscription\_id](#input\_application\_insights\_subscription\_id) | Subscription ID of the Application Insights instance. | `string` | n/a | yes |
| <a name="input_cosmos_account_endpoint"></a> [cosmos\_account\_endpoint](#input\_cosmos\_account\_endpoint) | Cosmos DB account endpoint URL (https://<account>.documents.azure.com:443/). | `string` | n/a | yes |
| <a name="input_cosmos_container_config"></a> [cosmos\_container\_config](#input\_cosmos\_container\_config) | Container name for the scheduler cursor / config doc. | `string` | `"config"` | no |
| <a name="input_cosmos_container_llm_usage"></a> [cosmos\_container\_llm\_usage](#input\_cosmos\_container\_llm\_usage) | Container name for scheduled-aggregation LLM usage docs. | `string` | `"llm-usage"` | no |
| <a name="input_cosmos_container_pii"></a> [cosmos\_container\_pii](#input\_cosmos\_container\_pii) | Container name for PII events. | `string` | `"pii-usage"` | no |
| <a name="input_cosmos_container_usage"></a> [cosmos\_container\_usage](#input\_cosmos\_container\_usage) | Container name for raw usage events. | `string` | `"usage"` | no |
| <a name="input_cosmos_database_name"></a> [cosmos\_database\_name](#input\_cosmos\_database\_name) | Cosmos DB SQL database hosting the four containers. | `string` | n/a | yes |
| <a name="input_dns_zone_id"></a> [dns\_zone\_id](#input\_dns\_zone\_id) | Private DNS zone ID for privatelink.azurewebsites.net. | `string` | `null` | no |
| <a name="input_enable_logic_app"></a> [enable\_logic\_app](#input\_enable\_logic\_app) | Master flag. When false, the module is a no-op. | `bool` | `false` | no |
| <a name="input_enable_private_networking"></a> [enable\_private\_networking](#input\_enable\_private\_networking) | Enable VNet integration + private endpoint. | `bool` | `false` | no |
| <a name="input_event_hub_namespace_fqdn"></a> [event\_hub\_namespace\_fqdn](#input\_event\_hub\_namespace\_fqdn) | Event Hubs namespace FQDN (e.g. <ns>.servicebus.windows.net). | `string` | n/a | yes |
| <a name="input_event_hub_pii_name"></a> [event\_hub\_pii\_name](#input\_event\_hub\_pii\_name) | Event Hub name for PII events (consumed by pii-usage-ingestion workflow). | `string` | n/a | yes |
| <a name="input_event_hub_usage_name"></a> [event\_hub\_usage\_name](#input\_event\_hub\_usage\_name) | Event Hub name for usage events (consumed by ai-usage-ingestion + ai-usage-streaming-ingestion workflows). | `string` | n/a | yes |
| <a name="input_location"></a> [location](#input\_location) | Azure region. | `string` | n/a | yes |
| <a name="input_log_analytics_workspace_id"></a> [log\_analytics\_workspace\_id](#input\_log\_analytics\_workspace\_id) | Log Analytics workspace ID for diagnostics. Empty to skip. | `string` | `""` | no |
| <a name="input_name_prefix"></a> [name\_prefix](#input\_name\_prefix) | Prefix for resource names. | `string` | n/a | yes |
| <a name="input_resource_group_name"></a> [resource\_group\_name](#input\_resource\_group\_name) | Resource group. | `string` | n/a | yes |
| <a name="input_sku_name"></a> [sku\_name](#input\_sku\_name) | App Service plan SKU (WS1 / WS2 / WS3). | `string` | `"WS1"` | no |
| <a name="input_subnet_id"></a> [subnet\_id](#input\_subnet\_id) | Subnet ID for VNet integration / private endpoint. | `string` | `null` | no |
| <a name="input_tags"></a> [tags](#input\_tags) | Tags to apply to all resources. | `map(string)` | `{}` | no |

## Outputs

| Name | Description |
| ---- | ----------- |
| <a name="output_default_hostname"></a> [default\_hostname](#output\_default\_hostname) | Default hostname of the Logic App. |
| <a name="output_id"></a> [id](#output\_id) | Logic App Standard resource ID. |
| <a name="output_name"></a> [name](#output\_name) | Logic App Standard name. |
| <a name="output_principal_id"></a> [principal\_id](#output\_principal\_id) | Logic App system-assigned identity principal ID. Grant this Event Hub Receiver + Cosmos Data Contributor + Monitoring Reader. |
| <a name="output_storage_account_id"></a> [storage\_account\_id](#output\_storage\_account\_id) | Resource ID of the runtime storage account. |
