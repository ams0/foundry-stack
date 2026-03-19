## Requirements

| Name | Version |
|------|---------|
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | >= 1.5 |
| <a name="requirement_azurerm"></a> [azurerm](#requirement\_azurerm) | >= 4.0 |

## Providers

| Name | Version |
|------|---------|
| <a name="provider_azurerm"></a> [azurerm](#provider\_azurerm) | 4.64.0 |

## Modules

No modules.

## Resources

| Name | Type |
|------|------|
| [azurerm_cosmosdb_account.this](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/cosmosdb_account) | resource |
| [azurerm_cosmosdb_sql_container.this](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/cosmosdb_sql_container) | resource |
| [azurerm_cosmosdb_sql_database.this](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/cosmosdb_sql_database) | resource |
| [azurerm_private_endpoint.this](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/private_endpoint) | resource |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_capacity_mode"></a> [capacity\_mode](#input\_capacity\_mode) | Cosmos DB capacity mode: 'serverless' (pay-per-use, cheapest) or 'provisioned' (fixed throughput) | `string` | `"serverless"` | no |
| <a name="input_databases"></a> [databases](#input\_databases) | Map of database name to list of container configs | <pre>map(list(object({<br/>    name                = string<br/>    partition_key_paths = list(string)<br/>  })))</pre> | <pre>{<br/>  "foundry": [<br/>    {<br/>      "name": "conversations",<br/>      "partition_key_paths": [<br/>        "/userId"<br/>      ]<br/>    },<br/>    {<br/>      "name": "agent-state",<br/>      "partition_key_paths": [<br/>        "/agentId"<br/>      ]<br/>    }<br/>  ]<br/>}</pre> | no |
| <a name="input_dns_zone_id"></a> [dns\_zone\_id](#input\_dns\_zone\_id) | Private DNS zone ID for Cosmos DB | `string` | `null` | no |
| <a name="input_enable_cosmosdb"></a> [enable\_cosmosdb](#input\_enable\_cosmosdb) | Whether to create Cosmos DB resources | `bool` | `false` | no |
| <a name="input_enable_private_networking"></a> [enable\_private\_networking](#input\_enable\_private\_networking) | Enable private endpoint and deny public access | `bool` | `false` | no |
| <a name="input_location"></a> [location](#input\_location) | Azure region | `string` | `"swedencentral"` | no |
| <a name="input_name_prefix"></a> [name\_prefix](#input\_name\_prefix) | Prefix for resource names | `string` | n/a | yes |
| <a name="input_provisioned_throughput"></a> [provisioned\_throughput](#input\_provisioned\_throughput) | Max throughput in RU/s when capacity\_mode is 'provisioned' (autoscale). Ignored for serverless. | `number` | `1000` | no |
| <a name="input_resource_group_name"></a> [resource\_group\_name](#input\_resource\_group\_name) | Name of the resource group | `string` | n/a | yes |
| <a name="input_subnet_id"></a> [subnet\_id](#input\_subnet\_id) | Subnet ID for private endpoint | `string` | `null` | no |
| <a name="input_tags"></a> [tags](#input\_tags) | Additional tags to merge with defaults | `map(string)` | `{}` | no |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_account_id"></a> [account\_id](#output\_account\_id) | Cosmos DB account resource ID |
| <a name="output_account_name"></a> [account\_name](#output\_account\_name) | Cosmos DB account name |
| <a name="output_connection_string"></a> [connection\_string](#output\_connection\_string) | Cosmos DB primary connection string |
| <a name="output_endpoint"></a> [endpoint](#output\_endpoint) | Cosmos DB account endpoint |
| <a name="output_primary_key"></a> [primary\_key](#output\_primary\_key) | Cosmos DB primary key |
