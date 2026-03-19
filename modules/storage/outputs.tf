output "storage_account_id" {
  description = "Storage account resource ID"
  value       = azurerm_storage_account.this.id
}

output "storage_account_name" {
  description = "Storage account name"
  value       = azurerm_storage_account.this.name
}

output "primary_blob_endpoint" {
  description = "Primary blob service endpoint"
  value       = azurerm_storage_account.this.primary_blob_endpoint
}

output "primary_dfs_endpoint" {
  description = "Primary DFS (Data Lake) endpoint"
  value       = azurerm_storage_account.this.primary_dfs_endpoint
}

output "primary_access_key" {
  description = "Primary access key"
  value       = azurerm_storage_account.this.primary_access_key
  sensitive   = true
}

output "principal_id" {
  description = "System-assigned managed identity principal ID"
  value       = azurerm_storage_account.this.identity[0].principal_id
}

output "containers" {
  description = "Map of container name to container resource"
  value       = { for k, v in azurerm_storage_container.this : k => v.name }
}
