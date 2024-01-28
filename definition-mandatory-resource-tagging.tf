locals {
  mandatory_resource_tag_name_prefix = var.mandatory_resource_tagging_policy.name
  mandatory_resource_tag_name_hash   = substr(md5(local.mandatory_resource_tag_name_prefix), 0, 4)

  policy_rule = {
    "if" = {
      "anyOf" = [for tag in var.mandatory_resource_tagging_policy.required_tags : {
        field  = "tags['${tag.key}']",
        exists = false
      }]
    },
    "then" = {
      "effect" = "[parameters('effect')]"
    }
  }
}

resource "azurerm_policy_definition" "mandatory_resource_tagging_policy" {
  name                = local.mandatory_resource_tag_name_hash
  policy_type         = "Custom"
  mode                = "Indexed"
  display_name        = "${var.mandatory_resource_tagging_policy.name} - Mandatory Tags"
  description         = "This policy enforces mandatory tags on resources."
  management_group_id = var.mandatory_resource_tagging_policy.management_group_id != null ? var.mandatory_resource_tagging_policy.management_group_id : (var.attempt_read_tenant_root_group ? data.azurerm_management_group.tenant_root_group[0].id : null)

  metadata = jsonencode({
    version  = "1.0.0",
    category = "Management"
  })

  policy_rule = jsonencode(local.policy_rule)

  parameters = jsonencode({
    "effect" = {
      "type" = "String",
      "metadata" = {
        "displayName" = "Effect",
        "description" = "Enable or disable the execution of the policy."
      },
      "allowedValues" = ["Audit", "Deny", "Disabled"],
      "defaultValue"  = var.mandatory_resource_tagging_policy.effect
    }
  })
}

resource "azurerm_management_group_policy_assignment" "mandatory_resource_tagging" {
  name                 = azurerm_policy_definition.mandatory_resource_tagging_policy.name
  management_group_id  = var.mandatory_resource_tagging_policy.management_group_id != null ? var.mandatory_resource_tagging_policy.management_group_id : (var.attempt_read_tenant_root_group ? data.azurerm_management_group.tenant_root_group[0].id : null)
  policy_definition_id = azurerm_policy_definition.mandatory_resource_tagging_policy.id
  enforce              = var.mandatory_resource_tagging_policy.enforce
  display_name         = azurerm_policy_definition.mandatory_resource_tagging_policy.display_name
  description          = "This policy assignment enforces mandatory tagging."

  non_compliance_message {
    content = var.mandatory_resource_tagging_policy.non_compliance_message != null ? var.mandatory_resource_tagging_policy.non_compliance_message : "PlatformPolicyInfo: The resource you have tried to deploy is restricted by mandatory tagging policy. Please ensure all mandatory tags are provided. Contact your administrator for assistance."
  }

  parameters = jsonencode({
    "effect" = {
      "value" = var.mandatory_resource_tagging_policy.effect
    }
  })
}

