#locals {
#  mandatory_resource_tag_name_prefix = var.mandatory_resource_tagging_policy.name
#  mandatory_resource_tag_name_hash   = substr(md5(local.mandatory_resource_tag_name_prefix), 0, 4)
#  mandatory_tags_as_string           = join(", ", [for s in var.mandatory_resource_tagging_policy.required_tags : format("%q", s)])
#}
#
#resource "azurerm_policy_definition" "mandatory_resource_tagging_policy" {
#  for_each            = var.mandatory_resource_tagging_policy.required_tags
#  name                = "${local.mandatory_resource_tag_name_hash}-${each.key}"
#  policy_type         = "Custom"
#  mode                = "Indexed"
#  display_name        = "${var.mandatory_resource_tagging_policy.name} - ${each.key}"
#  description         = "This policy enforces the '${each.key}' tag with value '${each.value}' on resources."
#  management_group_id = var.mandatory_resource_tagging_policy.management_group_id != null ? var.mandatory_resource_tagging_policy.management_group_id : (var.attempt_read_tenant_root_group ? data.azurerm_management_group.tenant_root_group[0].id : null)
#
#  metadata = jsonencode({
#    version  = "1.0.0",
#    category = "Management"
#  })
#
#  policy_rule = jsonencode({
#    "if" = {
#      "allOf" = [
#        {
#          "field"  = "[concat('tags[', parameters('tagName'), ']')]",
#          "notLike" = "[parameters('tagValue')]"
#        }
#      ]
#    },
#    "then" = {
#      "effect" = "[parameters('effect')]"
#    }
#  })
#
#  parameters = jsonencode({
#    "tagName" = {
#      "type" = "String",
#      "metadata" = {
#        "displayName" = "Tag Name",
#        "description" = "Name of the tag, such as '${each.key}'"
#      }
#    },
#    "tagValue" = {
#      "type" = "String",
#      "metadata" = {
#        "displayName" = "Tag Value",
#        "description" = "Value of the tag, such as '${each.value}'"
#      }
#    },
#    "effect" = {
#      "type" = "String",
#      "metadata" = {
#        "displayName" = "Effect",
#        "description" = "Enable or disable the execution of the policy."
#      },
#      "allowedValues" = ["Audit", "Deny", "Disabled"],
#      "defaultValue"  = var.mandatory_resource_tagging_policy.effect
#    }
#  })
#}
#
#
#resource "azurerm_management_group_policy_assignment" "mandatory_resource_tagging" {
#  for_each             = var.mandatory_resource_tagging_policy.required_tags
#  name                 = azurerm_policy_definition.mandatory_resource_tagging_policy[each.key].name
#  management_group_id = var.mandatory_resource_tagging_policy.management_group_id != null ? var.mandatory_resource_tagging_policy.management_group_id : (var.attempt_read_tenant_root_group ? data.azurerm_management_group.tenant_root_group[0].id : null)
#  policy_definition_id = azurerm_policy_definition.mandatory_resource_tagging_policy[each.key].id
#  enforce              = var.mandatory_resource_tagging_policy.enforce
#  display_name         = azurerm_policy_definition.mandatory_resource_tagging_policy[each.key].display_name
#  description          = "This policy assignment enforces the tag '${each.key}' with value '${each.value}'."
#
#    non_compliance_message {
#    content = var.mandatory_resource_tagging_policy.non_compliance_message != null ? var.mandatory_resource_tagging_policy.non_compliance_message : "PlatformPolicyInfo: The resource you have tried to deploy has been restricted by ${azurerm_policy_definition.mandatory_resource_tagging_policy[each.key].display_name} policy. You must provide a ${each.key}:${each.value} tag. Please contact your administrator for assistance."
#  }
#
#  parameters = jsonencode({
#    "tagName" = {
#      "value" = each.key
#    },
#    "tagValue" = {
#      "value" = each.value
#    },
#    "effect" = {
#      "value" = var.mandatory_resource_tagging_policy.effect
#    }
#  })
#}
