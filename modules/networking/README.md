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
| [azurerm_monitor_private_link_scope.this](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/monitor_private_link_scope) | resource |
| [azurerm_network_security_group.this](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/network_security_group) | resource |
| [azurerm_private_dns_zone.this](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/private_dns_zone) | resource |
| [azurerm_private_dns_zone_virtual_network_link.this](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/private_dns_zone_virtual_network_link) | resource |
| [azurerm_subnet.this](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/subnet) | resource |
| [azurerm_subnet_network_security_group_association.this](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/subnet_network_security_group_association) | resource |
| [azurerm_virtual_network.this](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/virtual_network) | resource |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_address_space"></a> [address\_space](#input\_address\_space) | VNet address space | `list(string)` | <pre>[<br/>  "10.0.0.0/16"<br/>]</pre> | no |
| <a name="input_enable_apim"></a> [enable\_apim](#input\_enable\_apim) | Whether APIM resources are enabled (controls DNS zone creation) | `bool` | `false` | no |
| <a name="input_enable_cosmosdb"></a> [enable\_cosmosdb](#input\_enable\_cosmosdb) | Whether Cosmos DB resources are enabled (controls DNS zone creation) | `bool` | `false` | no |
| <a name="input_enable_litellm"></a> [enable\_litellm](#input\_enable\_litellm) | Whether LiteLLM resources are enabled (controls DNS zone creation) | `bool` | `false` | no |
| <a name="input_enable_private_networking"></a> [enable\_private\_networking](#input\_enable\_private\_networking) | Enable VNet, subnets, NSGs, private DNS zones, and private endpoints | `bool` | `false` | no |
| <a name="input_enable_redis"></a> [enable\_redis](#input\_enable\_redis) | Whether Redis resources are enabled (controls DNS zone creation) | `bool` | `false` | no |
| <a name="input_location"></a> [location](#input\_location) | Azure region | `string` | `"swedencentral"` | no |
| <a name="input_name_prefix"></a> [name\_prefix](#input\_name\_prefix) | Prefix for all resource names | `string` | n/a | yes |
| <a name="input_resource_group_name"></a> [resource\_group\_name](#input\_resource\_group\_name) | Name of the resource group | `string` | n/a | yes |
| <a name="input_subnet_cidrs"></a> [subnet\_cidrs](#input\_subnet\_cidrs) | CIDR blocks for each service subnet | `map(string)` | <pre>{<br/>  "apim": "10.0.6.0/24",<br/>  "cosmosdb": "10.0.8.0/24",<br/>  "foundry": "10.0.1.0/24",<br/>  "keyvault": "10.0.5.0/24",<br/>  "litellm": "10.0.7.0/24",<br/>  "redis": "10.0.4.0/24",<br/>  "search": "10.0.3.0/24",<br/>  "storage": "10.0.2.0/24"<br/>}</pre> | no |
| <a name="input_tags"></a> [tags](#input\_tags) | Additional tags to merge with defaults | `map(string)` | `{}` | no |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_ampls_id"></a> [ampls\_id](#output\_ampls\_id) | ID of the Azure Monitor Private Link Scope |
| <a name="output_dns_zone_ids"></a> [dns\_zone\_ids](#output\_dns\_zone\_ids) | Map of DNS zone key to DNS zone ID |
| <a name="output_nsg_ids"></a> [nsg\_ids](#output\_nsg\_ids) | Map of NSG name to NSG ID |
| <a name="output_subnet_ids"></a> [subnet\_ids](#output\_subnet\_ids) | Map of subnet name to subnet ID |
| <a name="output_vnet_id"></a> [vnet\_id](#output\_vnet\_id) | ID of the virtual network |
