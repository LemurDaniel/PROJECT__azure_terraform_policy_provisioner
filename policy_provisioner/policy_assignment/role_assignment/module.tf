
# Create Role Assignment
resource "azurerm_role_assignment" "policy_by_id" {
  for_each = toset([
    for role in var.role_definition_ids :
    role
    if length(regexall("^/providers/microsoft.authorization/roledefinitions/[{]?[0-9a-fA-F]{8}-([0-9a-fA-F]{4}-){3}[0-9a-fA-F]{12}[}]?$", lower(role))) > 0
  ])

  scope              = var.assignment_scope
  role_definition_id = each.value
  principal_id       = var.principal_id
}


resource "azurerm_role_assignment" "policy_by_name" {
  for_each = toset([
    for role in var.role_definition_ids :
    role
    if length(regexall("^/providers/microsoft.authorization/roledefinitions/[{]?[0-9a-fA-F]{8}-([0-9a-fA-F]{4}-){3}[0-9a-fA-F]{12}[}]?$", lower(role))) == 0
  ])

  scope                = var.assignment_scope
  role_definition_name = each.value
  principal_id         = var.principal_id
}
