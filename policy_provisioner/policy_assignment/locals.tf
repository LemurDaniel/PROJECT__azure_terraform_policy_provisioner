
locals {

  enabled_policy_assignment_scopes = {
    for policy_assignment_name, config in var.policy_assignments_configurations :
    policy_assignment_name => {

      # All policies with effect 'Modify' or 'DeployIfNotExists' need an identity and an location.
      managedIdentity     = config.isBuiltInPolicy == true && length(regexall("dine-", config.assignment_name)) > 0 ? "SystemAssigned" : config.managedIdentity
      role_definition_ids = config.isBuiltInPolicy && config.roleDefinitionIds == [] ? var.default_assignment_role_ids : config.roleDefinitionIds

      name         = config.assignment_name
      display_name = config.display_name
      description  = config.description
      enforce      = config.enforce
      enabled      = config.enabled
      location     = config.location

      # Test: prevent reapply by value know after apply.
      policy_definition_id = config.isBuiltInPolicy ? config.associated_policy : (
        config.isPolicySet == false ?
        "${config.root_deployment_scope}/providers/Microsoft.Authorization/policyDefinitions/${config.associated_policy}" :
        "${config.root_deployment_scope}/providers/Microsoft.Authorization/policySetDefinitions/${config.associated_policy}"
      )

      parameters = {
        for param_name, param_value in config.parameters :
        param_name => {
          # Does the insertion of values into a list, given the parameter is of type list.
          # If not the try fail and it falls back to the literal value.
          value = try(
            # Unable to use inline if because the resulting values may have unmatching types => BOOL ? type(list) : type(string)
            distinct(flatten(concat(
              [
                for element in param_value :
                try(var.policy_injected_variables[substr(element, 2, length(element) - 3)], "'${element}' NOT_FOUND")
                if length(regexall("^\\$\\[[a-zA-Z_]*\\]$", element)) == 1
              ],
              [
                for element in param_value :
                element
                if length(regexall("^\\$\\[[a-zA-Z_]*\\]$", element)) == 0
              ]
            ))),
            # Replace a string literal with a variable
            length(regexall("^\\$\\[[a-zA-Z_]*\\]$", param_value)) == 0 ? param_value :
            var.policy_injected_variables[substr(param_value, 2, length(param_value) - 3)]
          )
        }
      }

      # Inject variables into not_scopes
      not_scopes = distinct(
        # Unable to use inline if because the resulting values may have unmatching types => BOOL ? type(list) : type(string)
        flatten(concat(
          [
            for not_scope in config.not_scopes :
            try(var.policy_injected_variables[substr(not_scope, 2, length(not_scope) - 3)], "'${not_scope}' NOT_FOUND")
            if length(regexall("^\\$\\[[a-zA-Z_]*\\]$", not_scope)) == 1
          ],
          [
            for not_scope in config.not_scopes :
            not_scope
            if length(regexall("^\\$\\[[a-zA-Z_]*\\]$", not_scope)) == 0
          ]
        ))
      )

    } if config.enabled == true
  }

}

