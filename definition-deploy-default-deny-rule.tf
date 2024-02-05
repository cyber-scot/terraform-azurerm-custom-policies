#locals {
#  deploy_default_deny_nsg_rule_name_prefix = var.deploy_default_deny_nsg_rule_policy.name
#  deploy_default_deny_nsg_rule_name_hash   = substr(md5(local.deploy_default_deny_nsg_rule_name_prefix), 0, 12)
#}
#
#
#resource "azurerm_policy_definition" "deploy_default_deny_nsg_rule_policy" {
#  name                = local.deploy_default_deny_nsg_rule_name_hash
#  policy_type         = "Custom"
#  mode                = "All"
#  display_name        = "${var.policy_prefix} - Deploy Default Deny NSG Rule exists"
#  description         = var.deploy_default_deny_nsg_rule_policy.description != null ? var.deploy_default_deny_nsg_rule_policy.description : "This policy appends the a default rule to all NSGs in the scope."
#  management_group_id = var.deploy_default_deny_nsg_rule_policy.management_group_id != null ? var.deploy_default_deny_nsg_rule_policy.management_group_id : (var.attempt_read_tenant_root_group ? data.azurerm_management_group.tenant_root_group[0].id : null)
#
#  metadata = jsonencode({
#    version  = "1.0.0",
#    category = "Networking"
#    author   = var.policy_prefix
#  })
#
#  policy_rule = jsonencode({
#    "if" = {
#      "equals" = "Microsoft.Network/networkSecurityGroups",
#      "field"  = "type"
#    },
#    "then" = {
#      "details" = {
#        "deployment" = {
#          "properties" = {
#            "mode" = "incremental",
#            "parameters" = {
#              "access" = {
#                "value" = "[parameters('access')]"
#              },
#              "description" = {
#                "value" = "[parameters('ruledescription')]"
#              },
#              "destinationAddressPrefix" = {
#                "value" = "[parameters('destinationAddressPrefix')]"
#              },
#              "destinationPortRange" = {
#                "value" = "[parameters('destinationPortRange')]"
#              },
#              "direction" = {
#                "value" = "[parameters('direction')]"
#              },
#              "nsgName" = {
#                "value" = "[field('name')]"
#              },
#              "priority" = {
#                "value" = "[parameters('priority')]"
#              },
#              "protocol" = {
#                "value" = "[parameters('protocol')]"
#              },
#              "rulename" = {
#                "value" = "[parameters('rulename')]"
#              },
#              "sourceAddressPrefix" = {
#                "value" = "[parameters('sourceAddressPrefix')]"
#              },
#              "sourcePortRange" = {
#                "value" = "[parameters('sourcePortRange')]"
#              }
#            },
#            "template" = {
#              "$schema"        = "http://schema.management.azure.com/schemas/2018-05-01/subscriptionDeploymentTemplate.json#",
#              "contentVersion" = "1.0.0.0",
#              "parameters" = {
#                "access" = {
#                  "type" = "String"
#                },
#                "description" = {
#                  "type" = "String"
#                },
#                "destinationAddressPrefix" = {
#                  "type" = "Array"
#                },
#                "destinationPortRange" = {
#                  "type" = "Array"
#                },
#                "direction" = {
#                  "type" = "String"
#                },
#                "nsgName" = {
#                  "type" = "string"
#                },
#                "priority" = {
#                  "type" = "String"
#                },
#                "protocol" = {
#                  "type" = "String"
#                },
#                "rulename" = {
#                  "type" = "String"
#                },
#                "sourceAddressPrefix" = {
#                  "type" = "Array"
#                },
#                "sourcePortRange" = {
#                  "type" = "Array"
#                }
#              },
#              "resources" = [
#                {
#                  "apiVersion" = "2019-11-01",
#                  "properties" = {
#                    "access"                    = "[parameters('access')]",
#                    "description"               = "[parameters('description')]",
#                    "destinationAddressPrefix"  = "[if(equals(length(parameters('destinationAddressPrefix')),1),parameters('destinationAddressPrefix'),json('null'))]",
#                    "destinationAddressPrefixs" = "[if(equals(length(parameters('destinationAddressPrefix')),1),json('null'),parameters('destinationAddressPrefix'))]",
#                    "destinationPortRange"      = "[if(equals(length(parameters('destinationPortRange')),1),parameters('destinationPortRange'),json('null'))]",
#                    "destinationPortRanges"     = "[if(equals(length(parameters('destinationPortRange')),1),json('null'),parameters('destinationPortRange'))]",
#                    "direction"                 = "[parameters('direction')]",
#                    "priority"                  = "[parameters('priority')]",
#                    "protocol"                  = "[parameters('protocol')]",
#                    "sourceAddressPrefix"       = "[if(equals(length(parameters('sourceAddressPrefix')),1),parameters('sourceAddressPrefix'),json('null'))]",
#                    "sourceAddressPrefixs"      = "[if(equals(length(parameters('sourceAddressPrefix')),1),json('null'),parameters('sourceAddressPrefix'))]",
#                    "sourcePortRange"           = "[if(equals(length(parameters('sourcePortRange')),1),parameters('sourcePortRange'),json('null'))]",
#                    "sourcePortRanges"          = "[if(equals(length(parameters('sourcePortRange')),1),json('null'),parameters('sourcePortRange'))]"
#                  },
#                  "rulename" = "[concat(parameters('nsgName'),'/',parameters('rulename'))]",
#                  "type"     = "Microsoft.Network/networkSecurityGroups/securityRules"
#                }
#              ]
#            }
#          }
#        },
#        "existenceCondition" = {
#          "count" = {
#            "field" = "Microsoft.Network/networkSecurityGroups/securityRules[*]",
#            "where" = {
#              "allOf" = [
#                {
#                  "equals" = "[parameters('rulename')]",
#                  "field"  = "Microsoft.Network/networkSecurityGroups/securityRules[*].name"
#                },
#                {
#                  "equals" = "[parameters('protocol')]",
#                  "field"  = "Microsoft.Network/networkSecurityGroups/securityRules[*].protocol"
#                },
#                {
#                  "anyOf" = [
#                    {
#                      "equals" = true,
#                      "value"  = "[equals(field('Microsoft.Network/networkSecurityGroups/securityRules[*].sourcePortRange'), parameters('sourcePortRange'))]"
#                    },
#                    {
#                      "equals" = true,
#                      "value"  = "[equals(field('Microsoft.Network/networkSecurityGroups/securityRules[*].sourcePortRanges'), parameters('sourcePortRange'))]"
#                    }
#                  ]
#                },
#                {
#                  "anyOf" = [
#                    {
#                      "equals" = true,
#                      "value"  = "[equals(field('Microsoft.Network/networkSecurityGroups/securityRules[*].destinationPortRange'), parameters('destinationPortRange'))]"
#                    },
#                    {
#                      "equals" = true,
#                      "value"  = "[equals(field('Microsoft.Network/networkSecurityGroups/securityRules[*].destinationPortRanges'), parameters('destinationPortRange'))]"
#                    }
#                  ]
#                },
#                {
#                  "anyOf" = [
#                    {
#                      "equals" = true,
#                      "value"  = "[equals(field('Microsoft.Network/networkSecurityGroups/securityRules[*].sourceAddressPrefix'), parameters('sourceAddressPrefix'))]"
#                    },
#                    {
#                      "equals" = true,
#                      "value"  = "[equals(field('Microsoft.Network/networkSecurityGroups/securityRules[*].sourceAddressPrefixes'), parameters('sourceAddressPrefix'))]"
#                    }
#                  ]
#                },
#                {
#                  "anyOf" = [
#                    {
#                      "equals" = true,
#                      "value"  = "[equals(field('Microsoft.Network/networkSecurityGroups/securityRules[*].destinationAddressPrefix'), parameters('destinationAddressPrefix'))]"
#                    },
#                    {
#                      "equals" = true,
#                      "value"  = "[equals(field('Microsoft.Network/networkSecurityGroups/securityRules[*].destinationAddressPrefixes'), parameters('destinationAddressPrefix'))]"
#                    }
#                  ]
#                },
#                {
#                  "equals" = "[parameters('access')]",
#                  "field"  = "Microsoft.Network/networkSecurityGroups/securityRules[*].access"
#                },
#                {
#                  "equals" = "[parameters('priority')]",
#                  "field"  = "Microsoft.Network/networkSecurityGroups/securityRules[*].priority"
#                },
#                {
#                  "equals" = "[parameters('direction')]",
#                  "field"  = "Microsoft.Network/networkSecurityGroups/securityRules[*].direction"
#                }
#              ]
#            }
#          },
#          "notEquals" = 0
#        },
#        "roleDefinitionIds" = "[parameters('roleDefinitionId')]"
#        "type"              = "Microsoft.Network/networkSecurityGroups/securityRules"
#      },
#      "effect" = "[parameters('effect')]"
#    }
#  })
#
#  parameters = jsonencode({
#    "access" = {
#      "type" = "String",
#      "metadata" = {
#        "description" = "The network traffic is allowed or denied. - Allow or Deny",
#        "displayName" = "access"
#      }
#    },
#    "destinationAddressPrefix" = {
#      "type" = "Array",
#      "metadata" = {
#        "description" = "The destination address prefix. CIDR or destination IP range. Asterisk '*' can also be used to match all source IPs. Default tags such as 'VirtualNetwork', 'AzureLoadBalancer' and 'Internet' can also be used.",
#        "displayName" = "destinationAddressPrefix"
#      }
#    },
#    "destinationPortRange" = {
#      "type" = "Array",
#      "metadata" = {
#        "description" = "The destination port or range. Integer or range between 0 and 65535. Asterisk '*' can also be used to match all ports.",
#        "displayName" = "destinationPortRange"
#      }
#    },
#    "direction" = {
#      "type" = "String",
#      "metadata" = {
#        "description" = "The direction of the rule. The direction specifies if rule will be evaluated on incoming or outgoing traffic. - Inbound or Outbound",
#        "displayName" = "direction"
#      }
#    },
#    "roleDefinitionId" = {
#      type = "Array"
#      metadata = {
#        "description" = "The role definition ids for this policy"
#        "displayName" = "roleDefinitionId"
#      }
#    }
#    "priority" = {
#      "type" = "String",
#      "metadata" = {
#        "description" = "The priority of the rule. The value can be between 100 and 4096. The priority number must be unique for each rule in the collection. The lower the priority number, the higher the priority of the rule.",
#        "displayName" = "priority"
#      }
#    },
#    "protocol" = {
#      "type" = "String",
#      "metadata" = {
#        "description" = "Network protocol this rule applies to. - Tcp, Udp, Icmp, Esp, *, Ah",
#        "displayName" = "protocol"
#      }
#    },
#    "ruledescription" = {
#      "type" = "String",
#      "metadata" = {
#        "description" = "The description of the rule.",
#        "displayName" = "description"
#      }
#    },
#    "rulename" = {
#      "type" = "String",
#      "metadata" = {
#        "description" = "This is the name of the security rule itself.",
#        "displayName" = "Rule Name"
#      }
#    },
#    "sourceAddressPrefix" = {
#      "type" = "Array",
#      "metadata" = {
#        "description" = "The CIDR or source IP range. Asterisk '*' can also be used to match all source IPs. Default tags such as 'VirtualNetwork', 'AzureLoadBalancer' and 'Internet' can also be used. If this is an ingress rule, specifies where network traffic originates from.",
#        "displayName" = "sourceAddressPrefix"
#      }
#    },
#    "sourcePortRange" = {
#      "type" = "Array",
#      "metadata" = {
#        "description" = "The source port or range. Integer or range between 0 and 65535. Asterisk '*' can also be used to match all ports.",
#        "displayName" = "sourcePortRange"
#      }
#    },
#    "effect" = {
#      "type" = "String",
#      "metadata" = {
#        "displayName" = "Effect",
#        "description" = "DeployIfNotExists, AuditIfNotExists or Disabled the execution of the Policy"
#      },
#      "allowedValues" = [
#        "DeployIfNotExists",
#        "AuditIfNotExists",
#        "Disabled"
#      ],
#      "defaultValue" = "DeployIfNotExists"
#    }
#  })
#}
#
#resource "azurerm_management_group_policy_assignment" "deploy_default_deny_nsg_rule_assignment" {
#  count                = var.deploy_default_deny_nsg_rule_policy.deploy_assignment ? 1 : 0
#  name                 = azurerm_policy_definition.deploy_default_deny_nsg_rule_policy.name
#  management_group_id  = var.deploy_default_deny_nsg_rule_policy.management_group_id != null ? var.deploy_default_deny_nsg_rule_policy.management_group_id : (var.attempt_read_tenant_root_group ? data.azurerm_management_group.tenant_root_group[0].id : null)
#  policy_definition_id = azurerm_policy_definition.deploy_default_deny_nsg_rule_policy.id
#  enforce              = var.deploy_default_deny_nsg_rule_policy.enforce != null ? var.deploy_default_deny_nsg_rule_policy.enforce : true
#  display_name         = azurerm_policy_definition.deploy_default_deny_nsg_rule_policy.display_name
#  description          = var.deploy_default_deny_nsg_rule_policy.description != null ? var.deploy_default_deny_nsg_rule_policy.description : "This policy sets an NSG rule inside an NSG based on parameters."
#  location             = var.deploy_default_deny_nsg_rule_policy.location
#
#  non_compliance_message {
#    content = var.deploy_default_deny_nsg_rule_policy.non_compliance_message != null ? var.deploy_default_deny_nsg_rule_policy.non_compliance_message : "PlatformPolicyInfo: The NSG you have tried to deploy has been restricted by ${azurerm_policy_definition.deploy_default_deny_nsg_rule_policy.display_name} policy. This policy ensures an NSG rule is deployed. Please contact your administrator for assistance."
#  }
#
#  identity {
#    type = "SystemAssigned"
#  }
#
#  parameters = jsonencode({
#    "rulename" = {
#      "value" = var.deploy_default_deny_nsg_rule_policy.nsg_rule_name
#    }
#    "ruledescription" = {
#      "value" = var.deploy_default_deny_nsg_rule_policy.nsg_rule_description
#    }
#    "protocol" = {
#      "value" = var.deploy_default_deny_nsg_rule_policy.protocol
#    }
#    "access" = {
#      "value" = var.deploy_default_deny_nsg_rule_policy.access
#    }
#    "roleDefinitionId" = {
#      "value" = var.deploy_default_deny_nsg_rule_policy.role_definition_id
#    }
#    "priority" = {
#      "value" = var.deploy_default_deny_nsg_rule_policy.priority
#    }
#    "direction" = {
#      "value" = var.deploy_default_deny_nsg_rule_policy.direction
#    }
#    "sourcePortRange" = {
#      "value" = var.deploy_default_deny_nsg_rule_policy.source_port_ranges
#    }
#    "destinationPortRange" = {
#      "value" = var.deploy_default_deny_nsg_rule_policy.destination_port_ranges
#    }
#    "sourceAddressPrefix" = {
#      "value" = var.deploy_default_deny_nsg_rule_policy.source_address_prefixes
#    }
#    "destinationAddressPrefix" = {
#      "value" = var.deploy_default_deny_nsg_rule_policy.destination_address_prefixes
#    }
#    "effect" = {
#      "value" = var.deploy_default_deny_nsg_rule_policy.effect
#    }
#  })
#}
#
#resource "azurerm_role_assignment" "deploy_default_deny_nsg_rule_role_assignment" {
#  for_each           = toset(var.deploy_default_deny_nsg_rule_policy.role_definition_id)
#  principal_id       = azurerm_management_group_policy_assignment.deploy_default_deny_nsg_rule_assignment[0].identity[0].principal_id
#  scope              = azurerm_management_group_policy_assignment.deploy_default_deny_nsg_rule_assignment[0].management_group_id
#  role_definition_id = each.value
#}
