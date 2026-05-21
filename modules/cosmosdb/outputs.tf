output "account_id" {
  description = "Cosmos DB account resource ID"
  value       = var.enable_cosmosdb ? azurerm_cosmosdb_account.this[0].id : null
}

output "account_name" {
  description = "Cosmos DB account name"
  value       = var.enable_cosmosdb ? azurerm_cosmosdb_account.this[0].name : null
}

output "endpoint" {
  description = "Cosmos DB account endpoint"
  value       = var.enable_cosmosdb ? azurerm_cosmosdb_account.this[0].endpoint : null
}

output "primary_key" {
  description = "Cosmos DB primary key"
  value       = var.enable_cosmosdb ? azurerm_cosmosdb_account.this[0].primary_key : null
  sensitive   = true
}

output "connection_string" {
  description = "Cosmos DB primary connection string"
  value       = var.enable_cosmosdb ? azurerm_cosmosdb_account.this[0].primary_sql_connection_string : null
  sensitive   = true
}

output "logic_app_database" {
  description = "Database name hosting the Logic App containers (only meaningful when create_logic_app_containers = true)."
  value       = var.create_logic_app_containers ? var.logic_app_database : null
}

output "logic_app_container_names" {
  description = "Map of Logic App container key → container name."
  value       = var.create_logic_app_containers ? { for k, c in var.logic_app_containers : k => c.name } : {}
}
