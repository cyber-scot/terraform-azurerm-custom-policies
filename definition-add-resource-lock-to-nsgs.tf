locals {
  add_resource_lock_to_nsg_name_prefix = var.add_resource_lock_to_nsg_policy.name
  add_resource_lock_to_nsg_name_hash   = substr(md5(local.add_resource_lock_to_nsg_name_prefix), 0, 12)
}

resource "azurerm_policy_definition" "add_resource_lock_to_nsg_policy" {
  name                = local.add_resource_lock_to_nsg_name_hash
  policy_type         = "Custom"
  mode                = "All"
  display_name        = "${var.policy_prefix} - Add Resource lock to NSG"
  description         = var.add_resource_lock_to_nsg_policy.description != null ? var.add_resource_lock_to_nsg_policy.description : "This policy stops the deletion of an NSG resource."
  management_group_id = var.add_resource_lock_to_nsg_policy.management_group_id != null ? var.add_resource_lock_to_nsg_policy.management_group_id : (var.attempt_read_tenant_root_group ? data.azurerm_management_group.tenant_root_group[0].id : null)

  metadata = jsonencode({
    version  = "1.0.0",
    category = "Management"
    author   = var.policy_prefix
  })

  policy_rule = jsonencode({
    "if" = {
      "allOf" = [
        {
          "field"  = "type",
          "equals" = "Microsoft.Network/networkSecurityGroups"
        },
        {
          "not" = {
            "field"  = "[concat('tags[', parameters('TagOfExclusion'), ']')]",
            "equals" = "[parameters('TagValue')]"
          }
        }
      ]
    },
    "then" = {
      "effect" = "[parameters('effect')]",
      "details" = {
        "type"            = "Microsoft.Authorization/locks",
        "evaluationDelay" = "AfterProvisioning",
        "existenceCondition" = {
          "field"  = "Microsoft.Authorization/locks/level",
          "equals" = "ReadOnly"
        },
        "deployment" = {
          "properties" = {
            "mode" = "incremental",
            "template" = {
              "$schema"        = "https://schema.management.azure.com/schemas/2015-01-01/deploymentTemplate.json#",
              "contentVersion" = "1.0.0.0",
              "resources" = [
                {
                  "name"       = "Auto locked by policy",
                  "type"       = "Microsoft.Authorization/locks",
                  "apiVersion" = "2020-05-01",
                  "properties" = {
                    "level" = "ReadOnly",
                    "notes" = "This lock was deployed automatically by Azure Policy to prevent the resource group and its containing resources from accidental deletion."
                  }
                }
              ]
            }
          }
        },
        "roleDefinitionIds" = [
          var.add_resource_lock_to_nsg_policy.role_definition_id
        ]
      }
    }
  })

  parameters = jsonencode({
    "TagOfExclusion" = {
      "type" = "String",
      "metadata" = {
        "displayName" = "Tag of environment to exclude",
        "description" = "If there is a need to exclude RGs from the audit based on a tag, you can do so. In this field, define which tag you want to check for it's value."
      },
      "defaultValue" = "SkipResourceLockCreation"
    },
    "TagValue" = {
      "type" = "String",
      "metadata" = {
        "displayName" = "Value of the tag for exclusion",
        "description" = "If you decided to configure an exclusion, you need to configure a specific value of the tag you defined. Put the tag value for exclusion in this field"
      },
      "defaultValue" = "true"
    },
    "effect" = {
      "type" = "String",
      "metadata" = {
        "displayName" = "Effect",
        "description" = "DeployIfNotExists, AuditIfNotExists or Disabled the execution of the Policy"
      },
      "allowedValues" = [
        "DeployIfNotExists",
        "AuditIfNotExists",
        "Disabled"
      ],
      "defaultValue" = "DeployIfNotExists"
    }
  })
}

resource "azurerm_management_group_policy_assignment" "add_resource_lock_to_nsg_assignment" {
  count                = var.add_resource_lock_to_nsg_policy.deploy_assignment ? 1 : 0
  name                 = azurerm_policy_definition.add_resource_lock_to_nsg_policy.name
  management_group_id  = var.add_resource_lock_to_nsg_policy.management_group_id != null ? var.add_resource_lock_to_nsg_policy.management_group_id : (var.attempt_read_tenant_root_group ? data.azurerm_management_group.tenant_root_group[0].id : null)
  policy_definition_id = azurerm_policy_definition.add_resource_lock_to_nsg_policy.id
  enforce              = var.add_resource_lock_to_nsg_policy.enforce != null ? var.add_resource_lock_to_nsg_policy.enforce : true
  display_name         = azurerm_policy_definition.add_resource_lock_to_nsg_policy.display_name
  description          = var.add_resource_lock_to_nsg_policy.description != null ? var.add_resource_lock_to_nsg_policy.description : "This policy adds a resource lock to NSGs"
  location             = var.add_resource_lock_to_nsg_policy.location

  identity {
    type = "SystemAssigned"
  }

  non_compliance_message {
    content = var.add_resource_lock_to_nsg_policy.non_compliance_message != null ? var.add_resource_lock_to_nsg_policy.non_compliance_message : "PlatformPolicyInfo: A resource lock has been added to the resource by ${azurerm_policy_definition.add_resource_lock_to_nsg_policy.display_name} policy. Please contact your administrator for assistance."
  }

  parameters = jsonencode({})
}

resource "azurerm_role_assignment" "add_resource_lock_to_nsg_assignment" {
  count              = var.add_resource_lock_to_nsg_policy.attempt_role_assignment == true ? 1 : 0
  principal_id       = azurerm_management_group_policy_assignment.add_resource_lock_to_nsg_assignment[0].identity[0].principal_id
  scope              = azurerm_management_group_policy_assignment.add_resource_lock_to_nsg_assignment[0].management_group_id
  role_definition_id = var.add_resource_lock_to_nsg_policy.role_definition_id
}
