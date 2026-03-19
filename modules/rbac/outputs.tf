output "role_assignment_ids" {
  description = "Map of role assignment key to assignment ID"
  value       = { for k, v in azurerm_role_assignment.this : k => v.id }
}
