module "custom_policies" {
  source = "cyber-scot/custom-policies/azurerm"


  non_privileged_role_restriction_policy = {
    deploy_assignment = true
    effect            = "Deny"

    non_privileged_role_definition_restricted_principal_types = [
      "User",
      "Group"
    ]
    non_privileged_role_definition_ids = [
      "/providers/Microsoft.Authorization/roleDefinitions/9980e02c-c2be-4d73-94e8-173b1dc7cf3c", # Virtual Machine Contributor
    ]
  }

  privileged_role_restriction_policy = {
    deploy_assignment = true
    effect            = "Deny"

    privileged_role_definition_restricted_principal_types = [
      "ServicePrincipal",
      "ManagedIdentity",
      "Application"
    ]
    privileged_role_definition_ids = [
      "/providers/Microsoft.Authorization/roleDefinitions/18d7d88d-d35e-4fb5-a5c3-7773c20a72d9", # User Access Administrator
    ]
  }

  match_mandatory_resource_tagging_policy = {
    deploy_assignment = true
    effect            = "Deny"

    required_tags = [
      {
        key     = "CostCentre"
        pattern = "#####"
      },
      {
        key     = "ResourceOwner"
        pattern = "*@cyber.scot"
      }
    ]
  }

  like_mandatory_resource_tagging_policy = {
    deploy_assignment = true
    effect            = "Deny"

    required_tags = [
      {
        key     = "CostCentre"
        pattern = "#####"
      },
      {
        key     = "ResourceOwner"
        pattern = "*@cyber.scot"
      }
    ]
  }

  append_default_deny_nsg_rule_policy = {
    deploy_assignment = true
    effect            = "Append"
  }

  deny_nsg_deletion_action_policy = {
    deploy_assignment = true
  }


}
