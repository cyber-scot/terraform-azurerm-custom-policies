locals {
  append_default_deny_nsg_rule_name_prefix = var.append_default_deny_nsg_rule_policy.name
  append_default_deny_nsg_rule_name_hash   = substr(md5(local.append_default_deny_nsg_rule_name_prefix), 0, 12)
}


resource "azurerm_policy_definition" "append_default_deny_nsg_rule_policy" {
  name                = local.append_default_deny_nsg_rule_name_hash
  policy_type         = "Custom"
  mode                = "All"
  display_name        = "${var.policy_prefix} - Append Default Deny NSG Rule exists"
  description         = var.append_default_deny_nsg_rule_policy.description != null ? var.append_default_deny_nsg_rule_policy.description : "This policy appends the a default rule to all NSGs in the scope."
  management_group_id = var.append_default_deny_nsg_rule_policy.management_group_id != null ? var.append_default_deny_nsg_rule_policy.management_group_id : (var.attempt_read_tenant_root_group ? data.azurerm_management_group.tenant_root_group[0].id : null)

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
        },
        {
          "field" = "name",
          "like"  = "[concat('*', parameters('targetSuffix'))]"
        },
        {
          "count" = {
            "field" = "Microsoft.Network/networkSecurityGroups/securityRules[*]",
            "where" = {
              "allOf" = [
                {
                  "field"  = "Microsoft.Network/networkSecurityGroups/securityRules[*].name",
                  "equals" = "[parameters('name')]"
                },
                {
                  "field"  = "Microsoft.Network/networkSecurityGroups/securityRules[*].protocol",
                  "equals" = "[parameters('protocol')]"
                },
                {
                  "anyOf" = [
                    {
                      "value"  = "[equals(field('Microsoft.Network/networkSecurityGroups/securityRules[*].sourcePortRanges'), parameters('sourcePortRanges'))]",
                      "equals" = true
                    },
                    {
                      "value"  = "[equals(field('Microsoft.Network/networkSecurityGroups/securityRules[*].sourcePortRanges'), parameters('sourcePortRanges'))]",
                      "equals" = true
                    }
                  ]
                },
                {
                  "anyOf" = [
                    {
                      "value"  = "[equals(field('Microsoft.Network/networkSecurityGroups/securityRules[*].destinationPortRanges'), parameters('destinationPortRanges'))]",
                      "equals" = true
                    },
                    {
                      "value"  = "[equals(field('Microsoft.Network/networkSecurityGroups/securityRules[*].destinationPortRanges'), parameters('destinationPortRanges'))]",
                      "equals" = true
                    }
                  ]
                },
                {
                  "anyOf" = [
                    {
                      "value"  = "[equals(field('Microsoft.Network/networkSecurityGroups/securityRules[*].sourceAddressPrefixes'), parameters('sourceAddressPrefixes'))]",
                      "equals" = true
                    },
                    {
                      "value"  = "[equals(field('Microsoft.Network/networkSecurityGroups/securityRules[*].sourceAddressPrefixeses'), parameters('sourceAddressPrefixes'))]",
                      "equals" = true
                    }
                  ]
                },
                {
                  "anyOf" = [
                    {
                      "value"  = "[equals(field('Microsoft.Network/networkSecurityGroups/securityRules[*].destinationAddressPrefixes'), parameters('destinationAddressPrefixes'))]",
                      "equals" = true
                    },
                    {
                      "value"  = "[equals(field('Microsoft.Network/networkSecurityGroups/securityRules[*].destinationAddressPrefixes'), parameters('destinationAddressPrefixes'))]",
                      "equals" = true
                    }
                  ]
                },
                {
                  "field"  = "Microsoft.Network/networkSecurityGroups/securityRules[*].access",
                  "equals" = "[parameters('access')]"
                },
                {
                  "field"  = "Microsoft.Network/networkSecurityGroups/securityRules[*].priority",
                  "equals" = "[parameters('priority')]"
                },
                {
                  "field"  = "Microsoft.Network/networkSecurityGroups/securityRules[*].direction",
                  "equals" = "[parameters('direction')]"
                }
              ]
            }
          },
          "equals" = 0
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
              "sourcePortRanges"           = "[if(equals(length(parameters('sourcePortRanges')), 1), parameters('sourcePortRanges')[0], json('null'))]",
              "sourcePortRanges"           = "[if(greater(length(parameters('sourcePortRanges')), 1), parameters('sourcePortRanges'), json('null'))]",
              "destinationPortRanges"      = "[if(equals(length(parameters('destinationPortRanges')), 1), parameters('destinationPortRanges')[0], json('null'))]",
              "destinationPortRanges"      = "[if(greater(length(parameters('destinationPortRanges')), 1), parameters('destinationPortRanges'), json('null'))]",
              "sourceAddressPrefixes"      = "[if(equals(length(parameters('sourceAddressPrefixes')), 1), parameters('sourceAddressPrefixes')[0], json('null'))]",
              "sourceAddressPrefixes"      = "[if(greater(length(parameters('sourceAddressPrefixes')), 1), parameters('sourceAddressPrefixes'), json('null'))]",
              "destinationAddressPrefixes" = "[if(equals(length(parameters('destinationAddressPrefixes')), 1), parameters('destinationAddressPrefixes')[0], json('null'))]",
              "destinationAddressPrefixes" = "[if(greater(length(parameters('destinationAddressPrefixes')), 1), parameters('destinationAddressPrefixes'), json('null'))]",
              "access"                     = "[parameters('access')]",
              "priority"                   = "[parameters('priority')]",
              "direction"                  = "[parameters('direction')]"
            }
          }
        }
      ]
    }
  })

  parameters = jsonencode({
    "name" = {
      "type" = "String",
      "metadata" = {
        "displayName" = "Rule Name",
        "description" = "This is the name of the security rule itself."
      }
    },
    "protocol" = {
      "type" = "String",
      "metadata" = {
        "displayName" = "protocol",
        "description" = "Network protocol this rule applies to. - Tcp, Udp, Icmp, Esp, *, Ah"
      }
    },
    "sourcePortRanges" = {
      "type" = "Array",
      "metadata" = {
        "displayName" = "sourcePortRanges",
        "description" = "The source port or range. Integer or range between 0 and 65535. Asterisk '*' can also be used to match all ports."
      }
    },
    "destinationPortRanges" = {
      "type" = "Array",
      "metadata" = {
        "displayName" = "destinationPortRanges",
        "description" = "The destination port or range. Integer or range between 0 and 65535. Asterisk '*' can also be used to match all ports."
      }
    },
    "sourceAddressPrefixes" = {
      "type" = "Array",
      "metadata" = {
        "displayName" = "sourceAddressPrefixes",
        "description" = "The CIDR or source IP range. Asterisk '*' can also be used to match all source IPs. Default tags such as 'VirtualNetwork', 'AzureLoadBalancer' and 'Internet' can also be used. If this is an ingress rule, specifies where network traffic originates from."
      }
    },
    "destinationAddressPrefixes" = {
      "type" = "Array",
      "metadata" = {
        "displayName" = "destinationAddressPrefixes",
        "description" = "The destination address prefix. CIDR or destination IP range. Asterisk '*' can also be used to match all source IPs. Default tags such as 'VirtualNetwork', 'AzureLoadBalancer' and 'Internet' can also be used."
      }
    },
    "access" = {
      "type" = "String",
      "metadata" = {
        "displayName" = "access",
        "description" = "The network traffic is allowed or denied. - Allow or Deny"
      }
    },
    "priority" = {
      "type" = "Integer",
      "metadata" = {
        "displayName" = "priority",
        "description" = "The priority of the rule. The value can be between 100 and 4096. The priority number must be unique for each rule in the collection. The lower the priority number, the higher the priority of the rule."
      }
    },
    "direction" = {
      "type" = "String",
      "metadata" = {
        "displayName" = "direction",
        "description" = "The direction of the rule. The direction specifies if rule will be evaluated on incoming or outgoing traffic. - Inbound or Outbound"
      }
    },
    "targetSuffix" = {
      "type" = "string",
      "metadata" = {
        "displayName" = "Targeted Suffix",
        "description" = "NSG's containing this suffix will have this policy applied to them."
      }
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


resource "azurerm_management_group_policy_assignment" "append_default_deny_nsg_rule_assignment" {
  count                = var.append_default_deny_nsg_rule_policy.deploy_assignment ? 1 : 0
  name                 = azurerm_policy_definition.append_default_deny_nsg_rule_policy.name
  management_group_id  = var.append_default_deny_nsg_rule_policy.management_group_id != null ? var.append_default_deny_nsg_rule_policy.management_group_id : (var.attempt_read_tenant_root_group ? data.azurerm_management_group.tenant_root_group[0].id : null)
  policy_definition_id = azurerm_policy_definition.append_default_deny_nsg_rule_policy.id
  enforce              = var.append_default_deny_nsg_rule_policy.enforce != null ? var.append_default_deny_nsg_rule_policy.enforce : true
  display_name         = azurerm_policy_definition.append_default_deny_nsg_rule_policy.display_name
  description          = var.append_default_deny_nsg_rule_policy.description != null ? var.append_default_deny_nsg_rule_policy.description : "This policy sets an NSG rule inside an NSG based on parameters."

  non_compliance_message {
    content = var.append_default_deny_nsg_rule_policy.non_compliance_message != null ? var.append_default_deny_nsg_rule_policy.non_compliance_message : "PlatformPolicyInfo: The NSG you have tried to deploy has been restricted by ${azurerm_policy_definition.append_default_deny_nsg_rule_policy.display_name} policy. This policy ensures an NSG rule is deployed. Please contact your administrator for assistance."
  }

  parameters = jsonencode({
    "name" = {
      "value" = var.append_default_deny_nsg_rule_policy.nsg_rule_name
    }
    "protocol" = {
      "value" = var.append_default_deny_nsg_rule_policy.protocol
    }
    "access" = {
      "value" = var.append_default_deny_nsg_rule_policy.access
    }
    "priority" = {
      "value" = var.append_default_deny_nsg_rule_policy.priority
    }
    "direction" = {
      "value" = var.append_default_deny_nsg_rule_policy.direction
    }
    "sourcePortRanges" = {
      "value" = var.append_default_deny_nsg_rule_policy.source_port_ranges
    }
    "destinationPortRanges" = {
      "value" = var.append_default_deny_nsg_rule_policy.destination_port_ranges
    }
    "sourceAddressPrefixes" = {
      "value" = var.append_default_deny_nsg_rule_policy.source_address_prefixes
    }
    "destinationAddressPrefixes" = {
      "value" = var.append_default_deny_nsg_rule_policy.destination_address_prefixes
    }
    "targetSuffix" = {
      "value" = var.append_default_deny_nsg_rule_policy.name_suffix
    }
    "effect" = {
      "value" = var.append_default_deny_nsg_rule_policy.effect
    }
  })
}

