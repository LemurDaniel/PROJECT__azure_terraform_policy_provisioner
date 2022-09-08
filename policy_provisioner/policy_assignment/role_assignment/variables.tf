
variable "role_definition_ids" {
  description = "(Required) List of roles to be assigned on scope."
  type        = list(string)
}

variable "assignment_scope" {
  description = "(Required) Scope on which to assign defined roles."
  type        = string
}

variable "principal_id" {
  description = "(Required) Principal id of the identy to be assigned with defined roles on scope."
  type        = string
}

  
