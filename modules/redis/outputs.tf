output "redis_cache_id" {
  description = "Redis cache resource ID"
  value       = var.enable_redis ? azurerm_redis_cache.this[0].id : null
}

output "hostname" {
  description = "Redis cache hostname"
  value       = var.enable_redis ? azurerm_redis_cache.this[0].hostname : null
}

output "port" {
  description = "Redis SSL port"
  value       = var.enable_redis ? azurerm_redis_cache.this[0].ssl_port : null
}

output "primary_access_key" {
  description = "Redis primary access key"
  value       = var.enable_redis ? azurerm_redis_cache.this[0].primary_access_key : null
  sensitive   = true
}

output "primary_connection_string" {
  description = "Redis primary connection string"
  value       = var.enable_redis ? azurerm_redis_cache.this[0].primary_connection_string : null
  sensitive   = true
}
