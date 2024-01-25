locals {
  role_restriction_name_prefix = var.role_restriction_policy.name
  role_restriction_name_hash   = substr(md5(local.role_restriction_name_prefix), 0, 12)
}

resource "azurerm_policy_definition" "role_restriction_policy" {
  name                = local.role_restriction_name_hash
  policy_type         = "Custom"
  mode                = "All"
  display_name        = "${var.policy_prefix} - Definition - Allowed Roles Based on Principal Type"
  description         = var.role_restriction_policy.description != null ? var.role_restriction_policy.description : "This policy allows specific roles for Service Principals, Enterprise Apps, or Managed Identities, and other roles for Users or Groups."
  management_group_id = var.role_restriction_policy.management_group_id != null ? var.role_restriction_policy.management_group_id : (var.attempt_read_tenant_root_group ? data.azurerm_management_group.tenant_root_group[0].id : null)

  metadata = jsonencode({
    version  = "1.0.0",
    category = "Identity and Access Management"
    author   = var.policy_prefix
  })

  policy_rule = jsonencode({
    "if" = {
      "allOf" = [
        {
          "field"  = "type"
          "equals" = "Microsoft.Authorization/roleAssignments"
        },
        {
          "anyOf" = [
            {
              "allOf" = [
                {
                  "field" = "Microsoft.Authorization/roleAssignments/principalType"
                  "in"    = var.role_restriction_policy.privileged_role_definition_restricted_principal_types
                },
                {
                  "field" = "Microsoft.Authorization/roleAssignments/roleDefinitionId"
                  "notIn" = "[parameters('privilegedRoleDefinitionIds')]"
                }
              ]
            },
            {
              "allOf" = [
                {
                  "field" = "Microsoft.Authorization/roleAssignments/principalType"
                  "in"    = var.role_restriction_policy.standard_role_definition_restricted_principal_types
                },
                {
                  "field" = "Microsoft.Authorization/roleAssignments/roleDefinitionId"
                  "notIn" = "[parameters('standardRoleDefinitionIds')]"
                }
              ]
            }
          ]
        }
      ]
    },
    "then" = {
      "effect" = "[parameters('effect')]"
    }
  })


  parameters = jsonencode({
    "privilegedRoleDefinitionIds" = {
      "type" = "Array"
      "metadata" = {
        "description" = "The list of role definition Ids allowed for the Privileged roles with the selected principalTypes"
        "displayName" = "Privileged Role Definitions"
      }
    },
    "standardRoleDefinitionIds" = {
      "type" = "Array"
      "metadata" = {
        "description" = "The list of role definition Ids allowed for the Standard roles with the selected principalTypes"
        "displayName" = "Standard Role Definitions"
      }
    },
    "effect" = {
      "type" = "String"
      "metadata" = {
        "displayName" = "Effect"
        "description" = "Enable or disable the execution of the policy."
      }
      "allowedValues" = ["Audit", "Deny", "Disabled"]
      "defaultValue"  = "Audit"
    }
  })
}

locals {
  extra_standard_role_definition_ids   = []
  extra_privileged_role_definition_ids = []
  standard_role_definition_ids         = distinct(concat(var.role_restriction_policy.standard_role_definition_ids, local.extra_standard_role_definition_ids))
  privileged_role_definition_ids       = distinct(concat(var.role_restriction_policy.privileged_role_definition_ids, local.extra_privileged_role_definition_ids))
}

resource "azurerm_management_group_policy_assignment" "role_restriction_assignment" {
  count                = var.role_restriction_policy.deploy_assignment ? 1 : 0
  name                 = local.role_restriction_name_hash
  management_group_id  = var.role_restriction_policy.management_group_id != null ? var.role_restriction_policy.management_group_id : (var.attempt_read_tenant_root_group ? data.azurerm_management_group.tenant_root_group[0].id : null)
  policy_definition_id = azurerm_policy_definition.role_restriction_policy.id
  enforce              = var.role_restriction_policy.enforce != null ? var.role_restriction_policy.enforce : true
  display_name         = "${var.policy_prefix} - Assignment - Allowed Roles Based on Principal Type"
  description          = var.role_restriction_policy.description != null ? var.role_restriction_policy.description : "This policy allows specific roles for Service Principals, Enterprise Apps, or Managed Identities, and other roles for Users or Groups."

  non_compliance_message {
    content = var.role_restriction_policy.non_compliance_message != null ? var.role_restriction_policy.non_compliance_message : "Error: The role you have tried to deploy has been restricted by ${var.policy_prefix} - Allowed Roles Based on Principal Type policy. Please contact your administrator for assistance."
  }

  parameters = jsonencode({
    "privilegedRoleDefinitionIds" = {
      "value" = local.privileged_role_definition_ids
    },
    "standardRoleDefinitionIds" = {
      "value" = local.standard_role_definition_ids
    },
    "effect" = {
      "value" = var.role_restriction_policy.effect
    }
  })
}
