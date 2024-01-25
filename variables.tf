variable "attempt_read_tenant_root_group" {
  type        = bool
  default     = true
  description = "Whether the module should attempt to read the tenant root group, your SPN may not have permissions"
}

variable "policy_prefix" {
  type        = string
  description = "The prefix to apply to the custom policies"
  default     = "[CyberScot]"
}

variable "role_restriction_policy" {
  description = "Configuration for the role restriction policy, including the management group ID and whether to deploy the policy assignment."
  type = object({
    name                                                  = optional(string, "restrict-roles-for-principal-type")
    management_group_id                                   = optional(string)
    deploy_assignment                                     = optional(bool, true)
    enforce                                               = optional(bool, true)
    non_compliance_message                                = optional(string)
    description                                           = optional(string)
    effect                                                = optional(string, "Audit")
    standard_role_definition_ids                          = optional(list(string), [])
    privileged_role_definition_ids                        = optional(list(string), [])
    standard_role_definition_restricted_principal_types   = optional(list(string), ["User", "Group"])
    privileged_role_definition_restricted_principal_types = optional(list(string), ["ServicePrincipal", "ManagedIdentity", "Application"])
  })
}
