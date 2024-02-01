locals {
  default_deny_nsg_rule_name_prefix = var.default_deny_nsg_rule_policy.name
  default_deny_nsg_rule_name_hash   = substr(md5(local.default_deny_nsg_rule_name_prefix), 0, 12)
}


resource "azurerm_policy_definition" "default_deny_nsg_rule_policy" {
  name                = local.default_deny_nsg_rule_name_hash
  policy_type         = "Custom"
  mode                = "All"
  display_name        = "${var.policy_prefix} - Ensure Default Deny NSG Rule exists"
  description         = var.default_deny_nsg_rule_policy.description != null ? var.default_deny_nsg_rule_policy.description : "This policy allows specific roles for specific principalTypes, which allows the administrator to allow greater access for, for example, Managed Identities used in automation, but deny similar access to users"
  management_group_id = var.default_deny_nsg_rule_policy.management_group_id != null ? var.default_deny_nsg_rule_policy.management_group_id : (var.attempt_read_tenant_root_group ? data.azurerm_management_group.tenant_root_group[0].id : null)

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
          "equals" = "Microsoft.Network/networkSecurityGroups"
        }
      ]
    },
    "then" = {
      "effect" = "[parameters('effect')]",
      "details" = [
        {
          "field" = "Microsoft.Network/networkSecurityGroups/securityRules[*]",
          "value" = {
            "name" = "[parameters('name')]",
            "properties" = {
              "protocol"                   = "[parameters('protocol')]",
              "sourcePortRange"            = "[if(equals(length(parameters('sourcePortRanges')), 1), first(parameters('sourcePortRanges')), '')]",
              "destinationPortRange"       = "[if(equals(length(parameters('destinationPortRanges')), 1), first(parameters('destinationPortRanges')), '')]",
              "sourceAddressPrefix"        = "[if(equals(length(parameters('sourceAddressPrefixes')), 1), first(parameters('sourceAddressPrefixes')), '')]",
              "destinationAddressPrefix"   = "[if(equals(length(parameters('destinationAddressPrefixes')), 1), first(parameters('destinationAddressPrefixes')), '')]",
              "access"                     = "[parameters('access')]",
              "priority"                   = "[parameters('priority')]",
              "direction"                  = "[parameters('direction')]",
              "sourcePortRanges"           = "[if(greater(length(parameters('sourcePortRanges')), 1), parameters('sourcePortRanges'), take(parameters('sourcePortRanges'),0))]",
              "destinationPortRanges"      = "[if(greater(length(parameters('destinationPortRanges')), 1), parameters('destinationPortRanges'), take(parameters('destinationPortRanges'),0))]",
              "sourceAddressPrefixes"      = "[if(greater(length(parameters('sourceAddressPrefixes')), 1), parameters('sourceAddressPrefixes'), take(parameters('sourceAddressPrefixes'),0))]",
              "destinationAddressPrefixes" = "[if(greater(length(parameters('destinationAddressPrefixes')), 1), parameters('destinationAddressPrefixes'), take(parameters('destinationAddressPrefixes'),0))]"
            }
          }
        }
      ]
    }
  })

  parameters = jsonencode({
    "name" = {
      "type" = "String"
    },
    "protocol" = {
      "type" = "String",
      "allowedvalues" = [
        "TCP",
        "UDP",
        "ICMP",
        "*"
      ]
    },
    "access" = {
      "type" = "String",
      "allowedvalues" = [
        "Allow",
        "Deny"
      ]
    },
    "priority" = {
      "type" = "String"
    },
    "direction" = {
      "type" = "String",
      "allowedvalues" = [
        "Inbound",
        "Outbound"
      ]
    },
    "sourcePortRanges" = {
      "type" = "Array"
    },
    "destinationPortRanges" = {
      "type" = "Array"
    },
    "sourceAddressPrefixes" = {
      "type" = "Array"
    },
    "destinationAddressPrefixes" = {
      "type" = "Array"
    },
    "effect" = {
      "type" = "String",
      "metadata" = {
        "displayName" = "Effect",
        "description" = "Append, Deny, Audit or Disable the execution of the Policy"
      },
      "allowedValues" = [
        "Append",
        "Deny",
        "Audit",
        "Disabled"
      ],
      "defaultValue" = "Append"
    }
  })
}


resource "azurerm_management_group_policy_assignment" "default_deny_nsg_rule_assignment" {
  count                = var.default_deny_nsg_rule_policy.deploy_assignment ? 1 : 0
  name                 = azurerm_policy_definition.default_deny_nsg_rule_policy.name
  management_group_id  = var.default_deny_nsg_rule_policy.management_group_id != null ? var.default_deny_nsg_rule_policy.management_group_id : (var.attempt_read_tenant_root_group ? data.azurerm_management_group.tenant_root_group[0].id : null)
  policy_definition_id = azurerm_policy_definition.default_deny_nsg_rule_policy.id
  enforce              = var.default_deny_nsg_rule_policy.enforce != null ? var.default_deny_nsg_rule_policy.enforce : true
  display_name         = azurerm_policy_definition.default_deny_nsg_rule_policy.display_name
  description          = var.default_deny_nsg_rule_policy.description != null ? var.default_deny_nsg_rule_policy.description : "This policy allows specific roles for ${local.privileged_principal_types_as_string}."

  non_compliance_message {
    content = var.default_deny_nsg_rule_policy.non_compliance_message != null ? var.default_deny_nsg_rule_policy.non_compliance_message : "PlatformPolicyInfo: The role you have tried to deploy has been restricted by ${azurerm_policy_definition.default_deny_nsg_rule_policy.display_name} policy. This role only allows specific roles for ${local.privileged_principal_types_as_string} Please contact your administrator for assistance."
  }

  parameters = jsonencode({
    "name" = {
      "value" = var.default_deny_nsg_rule_policy.name
    }
    "protocol" = {
      "value" = var.default_deny_nsg_rule_policy.protocol
    }
    "access" = {
      "value" = var.default_deny_nsg_rule_policy.access
    }
    "priority" = {
      "value" = var.default_deny_nsg_rule_policy.priority
    }
    "direction" = {
      "value" = var.default_deny_nsg_rule_policy.direction
    }
    "sourcePortRanges" = {
      "value" = var.default_deny_nsg_rule_policy.source_port_ranges
    }

    "effect" = {
      "value" = var.default_deny_nsg_rule_policy.effect
    }
  })
}

