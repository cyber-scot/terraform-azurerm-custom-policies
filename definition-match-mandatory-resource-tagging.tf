locals {
  match_mandatory_resource_tag_name_prefix = var.match_mandatory_resource_tagging_policy.name
  match_mandatory_resource_tag_name_hash   = substr(md5(local.match_mandatory_resource_tag_name_prefix), 0, 4)

  match_mandatory_non_compliance_messages = [for tag in var.match_mandatory_resource_tagging_policy.required_tags :
    format("PlatformPolicyInfo: The resource you have tried to deploy is restricted by mandatory match-pattern tagging policy. %s does not match the pattern %s. Please ensure all mandatory tags are provided. Contact your administrator for assistance.", tag.key, tag.pattern)
  ]

  match_mandatory_combined_non_compliance_message = join(" or ", local.match_mandatory_non_compliance_messages)

  match_mandatory_policy_rule = {
    "if" = {
      "allOf" = [for tag in var.match_mandatory_resource_tagging_policy.required_tags : {
        not = {
          "field" = "tags['${tag.key}']",
          "match" = tag.pattern
        }
      }]
    },
    "then" = {
      "effect" = "[parameters('effect')]"
    }
  }
}

resource "azurerm_policy_definition" "match_mandatory_resource_tagging_policy" {
  name                = local.match_mandatory_resource_tag_name_hash
  policy_type         = "Custom"
  mode                = "Indexed"
  display_name        = "${var.policy_prefix}  - Mandatory Resource Tags"
  description         = "This policy enforces mandatory tags on resources with a match pattern."
  management_group_id = var.match_mandatory_resource_tagging_policy.management_group_id != null ? var.match_mandatory_resource_tagging_policy.management_group_id : (var.attempt_read_tenant_root_group ? data.azurerm_management_group.tenant_root_group[0].id : null)

  metadata = jsonencode({
    version  = "1.0.0",
    category = "Management"
  })

  policy_rule = jsonencode(local.match_mandatory_policy_rule)

  parameters = jsonencode({
    "effect" = {
      "type" = "String",
      "metadata" = {
        "displayName" = "Effect",
        "description" = "Enable or disable the execution of the policy."
      },
      "allowedValues" = ["Audit", "Deny", "Disabled"],
      "defaultValue"  = var.match_mandatory_resource_tagging_policy.effect
    }
  })
}

resource "azurerm_management_group_policy_assignment" "match_mandatory_resource_tagging" {
  name                 = azurerm_policy_definition.match_mandatory_resource_tagging_policy.name
  management_group_id  = var.match_mandatory_resource_tagging_policy.management_group_id != null ? var.match_mandatory_resource_tagging_policy.management_group_id : (var.attempt_read_tenant_root_group ? data.azurerm_management_group.tenant_root_group[0].id : null)
  policy_definition_id = azurerm_policy_definition.match_mandatory_resource_tagging_policy.id
  enforce              = var.match_mandatory_resource_tagging_policy.enforce
  display_name         = azurerm_policy_definition.match_mandatory_resource_tagging_policy.display_name
  description          = "This policy assignment enforces mandatory tagging with a match pattern."

  non_compliance_message {
    content = var.match_mandatory_resource_tagging_policy.non_compliance_message != null ? var.match_mandatory_resource_tagging_policy.non_compliance_message : local.match_mandatory_combined_non_compliance_message
  }

  parameters = jsonencode({
    "effect" = {
      "value" = var.match_mandatory_resource_tagging_policy.effect
    }
  })
}

