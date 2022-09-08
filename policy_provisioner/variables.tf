variable "root_deployment_scope_mgm_name" {
  type        = string
  description = "(Required) Root Management Group of deployment scope ==> acfroot-dev/acfroot-prod."
}

variable "default_assignment_location" {
  type        = string
  description = "(Required) Default assignment location for dine/modify polices if not specified otherwise."
}

variable "custom_policy_definition_path" {
  type        = string
  description = "(Required) Library path to custom policy defintions. Relative to the module folder."
}

variable "mangagement_group_scopes" {
  description = "(Required) List of all management groups which need a policy assignment."
}

variable "policy_injected_variables" {
  description = "(Optional) Set of variables to be dynamically injected into policy parameters."
  default     = {}
}

variable "use_displayname" {
  description = "(Optional) Decides whether the Displayname should be used, when defined, rather than the file name."
  default     = false
}

variable "default_assignment_role_ids" {
  description = "(Optional) Default Roles for built-in DenyIfNotExists and Modify policies. (if none is provided in the assignment)"
  default = [
    "/providers/Microsoft.Authorization/roleDefinitions/b24988ac-6180-42a0-ab88-20f7382dd24c" # Contributor
  ]
}

