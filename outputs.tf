output "role_restriction_policy_id" {
  value       = azurerm_policy_definition.role_restriction_policy.id
  description = "The ID of the role restriction policy."
}

output "role_restriction_policy_management_group_id" {
  value       = var.role_restriction_policy.management_group_id
  description = "The management group ID associated with the role restriction policy."
}

output "role_restriction_policy_name" {
  value       = azurerm_policy_definition.role_restriction_policy.name
  description = "The name of the role restriction policy."
}
