

resource "azurerm_management_group_policy_assignment" "policy_assignment" {

  for_each = local.enabled_policy_assignment_scopes

  enforce      = each.value.enforce
  name         = each.value.name
  display_name = each.value.display_name
  description  = each.value.description

  management_group_id = format("%s%s", "/providers/Microsoft.Management/managementGroups/", var.policy_assignment_scope)

  parameters = length(keys(merge(each.value.parameters_list, each.value.parameters_single))) == 0 ? null : (
    jsonencode(merge(
      {
        for param_name, param_value in each.value.parameters_single :
        param_name => {
          # Attempt type conversions
          value = try(
            # Sure it's not nice code, but complex terraform stuff, doesn't allow nice code.
            can(regex("^tostring\\([0-9a-zA-Z]+\\)$", lower(trim(param_value, " ")))) ? (
            tostring(compact(regexall("([0-9]+)|(true)|(false)", param_value)[0])[0])) : regex(), # throw error. # Inline If converts tobool => tostring. Since Both side of Inline if need always be same type.
            tobool(param_value),
            tonumber(param_value),
            param_value
          )
        }
      },
      {
        for param_name, param_value in each.value.parameters_list :
        param_name => {
          value = [
            # Attempt type conversions
            for element in param_value :
            try(
              tobool(element),
              tonumber(element),
              element
            )
          ]
        }
    }))
  )

  policy_definition_id = each.value.policy_definition_id
  not_scopes           = each.value.not_scopes

  location = each.value.managedIdentity == "SystemAssigned" ? coalesce(each.value.location, var.default_assignment_location) : null

  dynamic "identity" {
    for_each = toset(each.value.managedIdentity == "SystemAssigned" ? [each.value.managedIdentity] : [])
    content {
      type = identity.value
      # identity_ids = []
    }
  }
}


module "role_assignments" {
  source = "./role_assignment"

  for_each = { for assignment_scope, config in local.enabled_policy_assignment_scopes :
    assignment_scope => config
    if config.managedIdentity == "SystemAssigned" ## length(config.role_definition_ids) > 0
  }

  role_definition_ids = each.value.role_definition_ids
  assignment_scope    = format("%s%s", "/providers/Microsoft.Management/managementGroups/", var.policy_assignment_scope)
  principal_id        = azurerm_management_group_policy_assignment.policy_assignment[each.key].identity[0].principal_id
  # principal_id        = try(azurerm_management_group_policy_assignment.policy_assignment[each.key].identity[0].principal_id, "")

}
