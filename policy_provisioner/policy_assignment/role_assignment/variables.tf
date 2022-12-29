
variable "role_definition_ids" {
  type        = list(string)
  nullable    = false
  description = "(Required) List of roles to be assigned on scope."
}

variable "assignment_scope" {
  type        = string
  nullable    = false
  description = "(Required) Scope on which to assign defined roles."
}

variable "principal_id" {
  type        = string
  nullable    = false
  description = "(Required) Principal id of the identy to be assigned with defined roles on scope."
}
