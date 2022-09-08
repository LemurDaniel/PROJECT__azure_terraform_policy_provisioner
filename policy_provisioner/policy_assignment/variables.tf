

variable "policy_assignment_scope" {
  description = "(Required) Scope on which the current polices are assigned."
}

variable "policy_assignments_configurations" {
  description = "(Required) Policy assignments on a given scope"
}

variable "default_assignment_location" {
  type        = string
  description = "(Required) Default assignment location for dine/modify polices if not specified otherwise."
}

variable "policy_injected_variables" {
  description = "(Optional) Set of variables to be dynamically injected into policy parameters."
  default     = {}
}

variable "default_assignment_role_ids" {
  description = "(Optional) Default Roles for built-in DenyIfNotExists and Modify policies. (if none is provided in the assignment)"
  default     = []
}
