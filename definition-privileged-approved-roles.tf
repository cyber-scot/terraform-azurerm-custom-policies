#locals {
#  privileged_role_restriction_name_prefix = var.privileged_role_restriction_policy.name
#  privileged_role_restriction_name_hash   = substr(md5(local.privileged_role_restriction_name_prefix), 0, 12)
#  privileged_principal_types_as_string    = join(", ", [for s in var.privileged_role_restriction_policy.privileged_role_definition_restricted_principal_types : format("%q", s)])
#}
#
#resource "azurerm_policy_definition" "privileged_role_restriction_policy" {
#  name                = local.privileged_role_restriction_name_hash
#  policy_type         = "Custom"
#  mode                = "All"
#  display_name        = "${var.policy_prefix} - Allowed Privileged Roles Based on Principal Type"
#  description         = var.privileged_role_restriction_policy.description != null ? var.privileged_role_restriction_policy.description : "This policy allows specific roles for specific principalTypes, which allows the administrator to allow greater access for, for example, Managed Identities used in automation, but deny similar access to users"
#  management_group_id = var.privileged_role_restriction_policy.management_group_id != null ? var.privileged_role_restriction_policy.management_group_id : (var.attempt_read_tenant_root_group ? data.azurerm_management_group.tenant_root_group[0].id : null)
#
#  metadata = jsonencode({
#    version  = "1.0.0",
#    category = "Identity and Access Management"
#    author   = var.policy_prefix
#  })
#
#  policy_rule = jsonencode({
#    "if" = {
#      "allOf" = [
#        {
#          "field"  = "type"
#          "equals" = "Microsoft.Authorization/roleAssignments"
#        },
#        {
#          "field" = "Microsoft.Authorization/roleAssignments/principalType"
#          "in"    = "[parameters('privilegedAllowedPrincipalTypes')]"
#        },
#        {
#          "field" = "Microsoft.Authorization/roleAssignments/roleDefinitionId"
#          "notIn" = "[parameters('privilegedRoleDefinitionIds')]"
#        }
#      ]
#    },
#    "then" = {
#      "effect" = "[parameters('effect')]"
#    }
#  })
#
#  parameters = jsonencode({
#    "privilegedAllowedPrincipalTypes" = {
#      "type" = "Array"
#      "metadata" = {
#        "description" = "The list of principal types that are allowed the privileged roles"
#        "displayName" = "Privileged roles Allowed Principal Types"
#      }
#    },
#    "privilegedRoleDefinitionIds" = {
#      "type" = "Array"
#      "metadata" = {
#        "description" = "The list of role definition Ids allowed for the User roles"
#        "displayName" = "Privileged Role Definition IDS"
#      }
#    },
#    "effect" = {
#      "type" = "String"
#      "metadata" = {
#        "displayName" = "Effect"
#        "description" = "Enable or disable the execution of the policy."
#      }
#      "allowedValues" = ["Audit", "Deny", "Disabled"]
#      "defaultValue"  = "Audit"
#    }
#  })
#}
#
#locals {
#  extra_privileged_role_definition_ids = []
#  privileged_role_definition_ids       = distinct(concat(var.privileged_role_restriction_policy.privileged_role_definition_ids, local.extra_privileged_role_definition_ids))
#}
#
#resource "azurerm_management_group_policy_assignment" "privileged_role_restriction_assignment" {
#  count                = var.privileged_role_restriction_policy.deploy_assignment ? 1 : 0
#  name                 = azurerm_policy_definition.privileged_role_restriction_policy.name
#  management_group_id  = var.privileged_role_restriction_policy.management_group_id != null ? var.privileged_role_restriction_policy.management_group_id : (var.attempt_read_tenant_root_group ? data.azurerm_management_group.tenant_root_group[0].id : null)
#  policy_definition_id = azurerm_policy_definition.privileged_role_restriction_policy.id
#  enforce              = var.privileged_role_restriction_policy.enforce != null ? var.privileged_role_restriction_policy.enforce : true
#  display_name         = azurerm_policy_definition.privileged_role_restriction_policy.display_name
#  description          = var.privileged_role_restriction_policy.description != null ? var.privileged_role_restriction_policy.description : "This policy allows specific roles for ${local.privileged_principal_types_as_string}."
#
#  non_compliance_message {
#    content = var.privileged_role_restriction_policy.non_compliance_message != null ? var.privileged_role_restriction_policy.non_compliance_message : "PlatformPolicyInfo: The role you have tried to deploy has been restricted by ${azurerm_policy_definition.privileged_role_restriction_policy.display_name} policy. This role only allows specific roles for ${local.privileged_principal_types_as_string} Please contact your administrator for assistance."
#  }
#
#  parameters = jsonencode({
#    "privilegedAllowedPrincipalTypes" = {
#      "value" = var.privileged_role_restriction_policy.privileged_role_definition_restricted_principal_types
#    },
#    "privilegedRoleDefinitionIds" = {
#      "value" = local.privileged_role_definition_ids
#    },
#    "effect" = {
#      "value" = var.privileged_role_restriction_policy.effect
#    }
#  })
#}
