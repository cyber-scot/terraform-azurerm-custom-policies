output "non_privileged_role_restriction_policy_id" {
  value       = azurerm_policy_definition.non_privileged_role_restriction_policy.id
  description = "The ID of the non-privileged role restriction policy."
}

output "non_privileged_role_restriction_policy_management_group_id" {
  value       = var.non_privileged_role_restriction_policy.management_group_id
  description = "The management group ID associated with the non-privileged role restriction policy."
}

output "non_privileged_role_restriction_policy_name" {
  value       = azurerm_policy_definition.non_privileged_role_restriction_policy.name
  description = "The name of the non-privileged role restriction policy."
}

output "privileged_role_restriction_policy_id" {
  value       = azurerm_policy_definition.privileged_role_restriction_policy.id
  description = "The ID of the role restriction policy."
}

output "privileged_role_restriction_policy_management_group_id" {
  value       = var.privileged_role_restriction_policy.management_group_id
  description = "The management group ID associated with the privileged role restriction policy."
}

output "privileged_role_restriction_policy_name" {
  value       = azurerm_policy_definition.privileged_role_restriction_policy.name
  description = "The name of the privileged role restriction policy."
}
