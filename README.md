```hcl
locals {
  role_restriction_name_prefix = var.role_restriction_policy.name
  role_restriction_name_hash   = substr(md5(local.role_restriction_name_prefix), 0, 12)
}

resource "azurerm_policy_definition" "role_restriction_policy" {
  name                = local.role_restriction_name_hash
  policy_type         = "Custom"
  mode                = "All"
  display_name        = "${var.policy_prefix} - Definition - Allowed Roles Based on Principal Type"
  description         = var.role_restriction_policy.description != null ? var.role_restriction_policy.description : "This policy allows specific roles for specific principalTypes, which allows the administrator to allow greater access for, for example, Managed Identities used in automation, but deny similar access to users"
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
    content = var.role_restriction_policy.non_compliance_message != null ? var.role_restriction_policy.non_compliance_message : "PlatformPolicyInfo: The role you have tried to deploy has been restricted by ${azurerm_policy_definition.role_restriction_policy.display_name} policy. Please contact your administrator for assistance."
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
```
## Requirements

No requirements.

## Providers

| Name | Version |
|------|---------|
| <a name="provider_azurerm"></a> [azurerm](#provider\_azurerm) | n/a |

## Modules

No modules.

## Resources

| Name | Type |
|------|------|
| [azurerm_management_group_policy_assignment.role_restriction_assignment](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/management_group_policy_assignment) | resource |
| [azurerm_policy_definition.role_restriction_policy](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/policy_definition) | resource |
| [azurerm_client_config.current](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/data-sources/client_config) | data source |
| [azurerm_management_group.tenant_root_group](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/data-sources/management_group) | data source |
| [azurerm_subscription.current](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/data-sources/subscription) | data source |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_attempt_read_tenant_root_group"></a> [attempt\_read\_tenant\_root\_group](#input\_attempt\_read\_tenant\_root\_group) | Whether the module should attempt to read the tenant root group, your SPN may not have permissions | `bool` | `true` | no |
| <a name="input_policy_prefix"></a> [policy\_prefix](#input\_policy\_prefix) | The prefix to apply to the custom policies | `string` | `"[CyberScot]"` | no |
| <a name="input_role_restriction_policy"></a> [role\_restriction\_policy](#input\_role\_restriction\_policy) | Configuration for the role restriction policy, this policy allows you to restrict specific role definition IDs to specific principal types, in the event you would like users to have different access to other things like Managed Identities (normally used in automation) | <pre>object({<br>    name                                                  = optional(string, "restrict-roles-for-principal-type")<br>    management_group_id                                   = optional(string)<br>    deploy_assignment                                     = optional(bool, true)<br>    enforce                                               = optional(bool, true)<br>    non_compliance_message                                = optional(string)<br>    description                                           = optional(string)<br>    effect                                                = optional(string, "Audit")<br>    standard_role_definition_ids                          = optional(list(string), [])<br>    privileged_role_definition_ids                        = optional(list(string), [])<br>    standard_role_definition_restricted_principal_types   = optional(list(string), ["User", "Group"])<br>    privileged_role_definition_restricted_principal_types = optional(list(string), ["ServicePrincipal", "ManagedIdentity", "Application"])<br>  })</pre> | n/a | yes |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_role_restriction_policy_id"></a> [role\_restriction\_policy\_id](#output\_role\_restriction\_policy\_id) | The ID of the role restriction policy. |
| <a name="output_role_restriction_policy_management_group_id"></a> [role\_restriction\_policy\_management\_group\_id](#output\_role\_restriction\_policy\_management\_group\_id) | The management group ID associated with the role restriction policy. |
| <a name="output_role_restriction_policy_name"></a> [role\_restriction\_policy\_name](#output\_role\_restriction\_policy\_name) | The name of the role restriction policy. |
