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
| [azurerm_role_assignment.additional](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/role_assignment) | resource |
| [azurerm_role_assignment.this](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/role_assignment) | resource |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_additional_role_assignments"></a> [additional\_role\_assignments](#input\_additional\_role\_assignments) | Additional custom role assignments | <pre>list(object({<br/>    principal_id         = string<br/>    role_definition_name = string<br/>    scope                = string<br/>  }))</pre> | `[]` | no |
| <a name="input_ai_services_principal_id"></a> [ai\_services\_principal\_id](#input\_ai\_services\_principal\_id) | Principal ID of the AI Services managed identity | `string` | n/a | yes |
| <a name="input_enable_redis"></a> [enable\_redis](#input\_enable\_redis) | Whether Redis role assignments should be created | `bool` | `false` | no |
| <a name="input_foundry_hub_principal_id"></a> [foundry\_hub\_principal\_id](#input\_foundry\_hub\_principal\_id) | Principal ID of the Foundry Hub managed identity | `string` | n/a | yes |
| <a name="input_key_vault_id"></a> [key\_vault\_id](#input\_key\_vault\_id) | Key Vault resource ID | `string` | n/a | yes |
| <a name="input_redis_cache_id"></a> [redis\_cache\_id](#input\_redis\_cache\_id) | Redis cache resource ID (optional) | `string` | `null` | no |
| <a name="input_search_service_id"></a> [search\_service\_id](#input\_search\_service\_id) | AI Search service resource ID | `string` | n/a | yes |
| <a name="input_storage_account_id"></a> [storage\_account\_id](#input\_storage\_account\_id) | Storage account resource ID | `string` | n/a | yes |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_role_assignment_ids"></a> [role\_assignment\_ids](#output\_role\_assignment\_ids) | Map of role assignment key to assignment ID |
