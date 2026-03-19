output "vnet_id" {
  description = "ID of the virtual network"
  value       = var.enable_private_networking ? azurerm_virtual_network.this[0].id : null
}

output "subnet_ids" {
  description = "Map of subnet name to subnet ID"
  value       = { for k, v in azurerm_subnet.this : k => v.id }
}

output "dns_zone_ids" {
  description = "Map of DNS zone key to DNS zone ID"
  value       = { for k, v in azurerm_private_dns_zone.this : k => v.id }
}

output "nsg_ids" {
  description = "Map of NSG name to NSG ID"
  value       = { for k, v in azurerm_network_security_group.this : k => v.id }
}

output "ampls_id" {
  description = "ID of the Azure Monitor Private Link Scope"
  value       = var.enable_private_networking ? azurerm_monitor_private_link_scope.this[0].id : null
}
