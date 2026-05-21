output "id" {
  description = "Logic App Standard resource ID."
  value       = var.enable_logic_app ? azurerm_logic_app_standard.this[0].id : null
}

output "name" {
  description = "Logic App Standard name."
  value       = var.enable_logic_app ? azurerm_logic_app_standard.this[0].name : null
}

output "principal_id" {
  description = "Logic App system-assigned identity principal ID. Grant this Event Hub Receiver + Cosmos Data Contributor + Monitoring Reader."
  value       = var.enable_logic_app ? azurerm_logic_app_standard.this[0].identity[0].principal_id : null
}

output "default_hostname" {
  description = "Default hostname of the Logic App."
  value       = var.enable_logic_app ? azurerm_logic_app_standard.this[0].default_hostname : null
}

output "storage_account_id" {
  description = "Resource ID of the runtime storage account."
  value       = var.enable_logic_app ? azurerm_storage_account.runtime[0].id : null
}
