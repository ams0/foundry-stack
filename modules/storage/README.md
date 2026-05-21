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
| [azurerm_private_endpoint.blob](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/private_endpoint) | resource |
| [azurerm_private_endpoint.dfs](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/private_endpoint) | resource |
| [azurerm_storage_account.this](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/storage_account) | resource |
| [azurerm_storage_account_network_rules.this](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/storage_account_network_rules) | resource |
| [azurerm_storage_container.this](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/storage_container) | resource |

## Inputs

| Name | Description | Type | Default | Required |
| ---- | ----------- | ---- | ------- | :------: |
| <a name="input_account_replication_type"></a> [account\_replication\_type](#input\_account\_replication\_type) | Storage account replication type | `string` | `"LRS"` | no |
| <a name="input_account_tier"></a> [account\_tier](#input\_account\_tier) | Storage account tier | `string` | `"Standard"` | no |
| <a name="input_containers"></a> [containers](#input\_containers) | List of blob containers to create | `list(string)` | <pre>[<br/>  "documents",<br/>  "chunks",<br/>  "embeddings",<br/>  "models"<br/>]</pre> | no |
| <a name="input_dns_zone_ids"></a> [dns\_zone\_ids](#input\_dns\_zone\_ids) | Map of DNS zone IDs: keys 'blob' and 'dfs' | `map(string)` | `{}` | no |
| <a name="input_enable_private_networking"></a> [enable\_private\_networking](#input\_enable\_private\_networking) | Enable private endpoint and deny public access | `bool` | `false` | no |
| <a name="input_location"></a> [location](#input\_location) | Azure region | `string` | `"swedencentral"` | no |
| <a name="input_name_prefix"></a> [name\_prefix](#input\_name\_prefix) | Prefix for resource names | `string` | n/a | yes |
| <a name="input_resource_group_name"></a> [resource\_group\_name](#input\_resource\_group\_name) | Name of the resource group | `string` | n/a | yes |
| <a name="input_subnet_id"></a> [subnet\_id](#input\_subnet\_id) | Subnet ID for private endpoint (required if enable\_private\_networking=true) | `string` | `null` | no |
| <a name="input_tags"></a> [tags](#input\_tags) | Additional tags to merge with defaults | `map(string)` | `{}` | no |

## Outputs

| Name | Description |
| ---- | ----------- |
| <a name="output_containers"></a> [containers](#output\_containers) | Map of container name to container resource |
| <a name="output_primary_access_key"></a> [primary\_access\_key](#output\_primary\_access\_key) | Primary access key |
| <a name="output_primary_blob_endpoint"></a> [primary\_blob\_endpoint](#output\_primary\_blob\_endpoint) | Primary blob service endpoint |
| <a name="output_primary_dfs_endpoint"></a> [primary\_dfs\_endpoint](#output\_primary\_dfs\_endpoint) | Primary DFS (Data Lake) endpoint |
| <a name="output_principal_id"></a> [principal\_id](#output\_principal\_id) | System-assigned managed identity principal ID |
| <a name="output_storage_account_id"></a> [storage\_account\_id](#output\_storage\_account\_id) | Storage account resource ID |
| <a name="output_storage_account_name"></a> [storage\_account\_name](#output\_storage\_account\_name) | Storage account name |
