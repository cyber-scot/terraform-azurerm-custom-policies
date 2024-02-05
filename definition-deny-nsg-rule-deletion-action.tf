locals {
  deny_nsg_deletion_action_name_prefix = var.deny_nsg_deletion_action_policy.name
  deny_nsg_deletion_action_name_hash   = substr(md5(local.deny_nsg_deletion_action_name_prefix), 0, 12)
}


resource "azurerm_policy_definition" "deny_nsg_deletion_action_policy" {
  name                = local.deny_nsg_deletion_action_name_hash
  policy_type         = "Custom"
  mode                = "Indexed"
  display_name        = "${var.policy_prefix} - Deny NSG Deletion"
  description         = var.deny_nsg_deletion_action_policy.description != null ? var.deny_nsg_deletion_action_policy.description : "This policy stops the deletion of an NSG resource."
  management_group_id = var.deny_nsg_deletion_action_policy.management_group_id != null ? var.deny_nsg_deletion_action_policy.management_group_id : (var.attempt_read_tenant_root_group ? data.azurerm_management_group.tenant_root_group[0].id : null)

  metadata = jsonencode({
    version  = "1.0.0",
    category = "Networking"
    author   = var.policy_prefix
  })

  policy_rule = jsonencode({
    "if" = {
      "allOf" = [
        {
          "field"  = "type",
          "equals" = "Microsoft.Network/networkSecurityGroups/securityRules"
        },
      ]
    },
    "then" = {
      "effect" = "denyAction",
      "details" = {
        "actionNames" = [
          "delete"
        ],
        "cascadeBehaviors" = {
          "resourceGroup" = "deny"
        }
      }
    }
  })

  parameters = jsonencode({})
}

resource "azurerm_management_group_policy_assignment" "deny_nsg_deletion_action_assignment" {
  count                = var.deny_nsg_deletion_action_policy.deploy_assignment ? 1 : 0
  name                 = azurerm_policy_definition.deny_nsg_deletion_action_policy.name
  management_group_id  = var.deny_nsg_deletion_action_policy.management_group_id != null ? var.deny_nsg_deletion_action_policy.management_group_id : (var.attempt_read_tenant_root_group ? data.azurerm_management_group.tenant_root_group[0].id : null)
  policy_definition_id = azurerm_policy_definition.deny_nsg_deletion_action_policy.id
  enforce              = var.deny_nsg_deletion_action_policy.enforce != null ? var.deny_nsg_deletion_action_policy.enforce : true
  display_name         = azurerm_policy_definition.deny_nsg_deletion_action_policy.display_name
  description          = var.deny_nsg_deletion_action_policy.description != null ? var.deny_nsg_deletion_action_policy.description : "This policy sets denys an NSG from being deleted"

  non_compliance_message {
    content = var.deny_nsg_deletion_action_policy.non_compliance_message != null ? var.deny_nsg_deletion_action_policy.non_compliance_message : "PlatformPolicyInfo: You cannot delete this NSG as it is protected by by ${azurerm_policy_definition.deny_nsg_deletion_action_policy.display_name} policy. Please contact your administrator for assistance."
  }

  parameters = jsonencode({})
}
