variable "root_deployment_scope_mgm_name" {
  type        = string
  nullable    = false
  description = "(Required) Root Management Group of deployment scope ==> acfroot-dev/acfroot-prod."
}

variable "default_assignment_location" {
  type        = string
  nullable    = false
  description = "(Required) Default assignment location for dine/modify polices if not specified otherwise."
}

variable "custom_policy_definition_path" {
  type        = string
  nullable    = false
  description = "(Required) Library path to custom policy defintions. Relative to the module folder."
}

variable "mangagement_group_scopes" {
  type        = list(string)
  nullable    = false
  description = "(Required) List of all management groups which need a policy assignment."
}

variable "policy_injected_variables" {
  type        = any
  nullable    = false
  default     = {}
  description = "(Optional) Set of variables to be dynamically injected into policy parameters."
}

variable "use_displayname" {
  type        = bool
  nullable    = false
  default     = false
  description = "(Optional) Decides whether the Displayname should be used, when defined, rather than the file name."
}

variable "default_assignment_role_ids" {
  type     = list(string)
  nullable = false
  default = [
    "/providers/Microsoft.Authorization/roleDefinitions/b24988ac-6180-42a0-ab88-20f7382dd24c" # Contributor
  ]
  description = "(Optional) Default Roles for built-in DenyIfNotExists and Modify policies. (if none is provided in the assignment)"
}

