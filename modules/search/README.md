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
| [azurerm_private_endpoint.this](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/private_endpoint) | resource |
| [azurerm_search_service.this](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/search_service) | resource |

## Inputs

| Name | Description | Type | Default | Required |
| ---- | ----------- | ---- | ------- | :------: |
| <a name="input_dns_zone_id"></a> [dns\_zone\_id](#input\_dns\_zone\_id) | Private DNS zone ID for search | `string` | `null` | no |
| <a name="input_enable_private_networking"></a> [enable\_private\_networking](#input\_enable\_private\_networking) | Enable private endpoint and deny public access | `bool` | `false` | no |
| <a name="input_location"></a> [location](#input\_location) | Azure region | `string` | `"swedencentral"` | no |
| <a name="input_name_prefix"></a> [name\_prefix](#input\_name\_prefix) | Prefix for resource names | `string` | n/a | yes |
| <a name="input_partition_count"></a> [partition\_count](#input\_partition\_count) | Number of search partitions | `number` | `1` | no |
| <a name="input_replica_count"></a> [replica\_count](#input\_replica\_count) | Number of search replicas | `number` | `1` | no |
| <a name="input_resource_group_name"></a> [resource\_group\_name](#input\_resource\_group\_name) | Name of the resource group | `string` | n/a | yes |
| <a name="input_sku"></a> [sku](#input\_sku) | Search service SKU | `string` | `"standard"` | no |
| <a name="input_subnet_id"></a> [subnet\_id](#input\_subnet\_id) | Subnet ID for private endpoint | `string` | `null` | no |
| <a name="input_tags"></a> [tags](#input\_tags) | Additional tags to merge with defaults | `map(string)` | `{}` | no |

## Outputs

| Name | Description |
| ---- | ----------- |
| <a name="output_endpoint"></a> [endpoint](#output\_endpoint) | Search service endpoint URL |
| <a name="output_primary_key"></a> [primary\_key](#output\_primary\_key) | Search service primary admin key |
| <a name="output_principal_id"></a> [principal\_id](#output\_principal\_id) | System-assigned managed identity principal ID |
| <a name="output_search_service_id"></a> [search\_service\_id](#output\_search\_service\_id) | Search service resource ID |
| <a name="output_search_service_name"></a> [search\_service\_name](#output\_search\_service\_name) | Search service name |
