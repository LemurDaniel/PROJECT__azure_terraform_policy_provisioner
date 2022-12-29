
variable "policy_assignments_configurations" {
  type = map(
    object({
      isBuiltInPolicy = bool
      isPolicySet     = bool

      root_deployment_scope = string

      display_name    = string
      assignment_name = string
      description     = string

      associated_policy = string
      // Terraform type constrained limitation.
      // Terraform apperently can't infer a base type for all elements via any,
      // when value in parameters are 'list' or single 'string'
      parameters_single = map(map(string))
      parameters_list   = map(list(map(string)))

      not_scopes = list(string)
      location   = optional(string)
      enforce    = optional(string)
      enabled    = bool

      metadata          = map(string)
      roleDefinitionIds = any //list(string)
      managedIdentity   = optional(string)
    })
  )
  nullable    = false
  description = "(Required) Policy assignments on a given scope"
}

variable "policy_assignment_scope" {
  type        = string
  nullable    = false
  description = "(Required) Scope on which the current polices are assigned."
}

variable "default_assignment_location" {
  type        = string
  nullable    = false
  description = "(Required) Default assignment location for dine/modify polices if not specified otherwise."
}

variable "policy_injected_variables" {
  type        = any # A map of strings or lists of string with a depth of 1.
  nullable    = false
  default     = {}
  description = "(Optional) Set of variables to be dynamically injected into policy parameters."
}

variable "default_assignment_role_ids" {
  type        = list(string)
  nullable    = false
  default     = []
  description = "(Optional) Default Roles for built-in DenyIfNotExists and Modify policies. (if none is provided in the assignment)"
}
