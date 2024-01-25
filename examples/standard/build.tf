module "policies" {
  source = "../../"


  role_restriction_policy = {
    deploy_assignment = true
    effect            = "Deny"
    standard_role_definition_restricted_principal_types = [
      "User",
      "Group"
    ]
    standard_role_definition_ids = [
      "/providers/Microsoft.Authorization/roleDefinitions/9980e02c-c2be-4d73-94e8-173b1dc7cf3c", # Virtual Machine Contributor
    ]

    privileged_role_definition_ids = [
      "/providers/Microsoft.Authorization/roleDefinitions/18d7d88d-d35e-4fb5-a5c3-7773c20a72d9", # User Access Administrator
    ]
    privileged_role_definition_restricted_principal_types = [
      "ServicePrincipal",
      "ManagedIdentity",
      "Application"
    ]
  }
}
