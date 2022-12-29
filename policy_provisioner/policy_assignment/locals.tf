
locals {

  enabled_policy_assignment_scopes = {
    for policy_assignment_name, config in var.policy_assignments_configurations :
    policy_assignment_name => {

      # All policies with effect 'Modify' or 'DeployIfNotExists' need an identity and an location.
      managedIdentity     = config.isBuiltInPolicy == true && length(regexall("dine-", config.assignment_name)) > 0 ? "SystemAssigned" : config.managedIdentity
      role_definition_ids = config.isBuiltInPolicy && length(config.roleDefinitionIds) == 0 ? var.default_assignment_role_ids : config.roleDefinitionIds

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

      parameters_list = {
        for param_name, param_value in config.parameters_list :
        param_name => distinct(flatten(
          [
            for single_entry in param_value :
            # single_entry is Map of index => regex_capture

            ##########################
            # Does the same as below, except for every single entry in list.
            try(
              join("", values(
                merge(
                  single_entry,
                  {
                    # Does a replacement of injected variables on any regex-captured substrings.
                    for str_index, reg_capture in single_entry :
                    str_index => try(
                      var.policy_injected_variables[substr(reg_capture, 2, length(reg_capture) - 3)],
                      "'${reg_capture}' NOT_FOUND"
                    )
                    if length(regexall("^\\$\\[[a-zA-Z_0-9]*\\]$", reg_capture)) == 1
                  }
                ))
              ),
              # This is when not string interpolation but, appending list on list is wanted.
              flatten(values(
                merge(
                  single_entry,
                  {
                    # Does a replacement of injected variables on any regex-captured substrings.
                    for str_index, reg_capture in single_entry :
                    str_index => try(
                      var.policy_injected_variables[substr(reg_capture, 2, length(reg_capture) - 3)],
                      "'${reg_capture}' NOT_FOUND"
                    )
                    if length(regexall("^\\$\\[[a-zA-Z_0-9]*\\]$", reg_capture)) == 1
                  }
                ))
              )
            )
            ##########################

          ]
        ))
      }

      parameters_single = {
        for param_name, param_value in config.parameters_single :
        param_name => join("", values(
          merge(
            # The higher module creates a map of indexs with all string elements and captured regex groups
            # This is importand to keep the right order after merging and joining everything back together.
            # A normal list with inline ifs is not possible du to unmatching types like: => BOOL ? type(list) : type(string)
            param_value,
            {
              # Does a replacement of injected variables on any regex-captured substrings.
              for str_index, reg_capture in param_value :
              str_index => tostring(
                try(
                  var.policy_injected_variables[substr(reg_capture, 2, length(reg_capture) - 3)],
                  "'${reg_capture}' NOT_FOUND"
                )
              )
              if length(regexall("^\\$\\[[a-zA-Z_0-9]*\\]$", reg_capture)) == 1
            }
          )
        ))
      }


      # Inject variables into not_scopes
      not_scopes = distinct(
        # Unable to use inline if because the resulting values may have unmatching types => BOOL ? type(list) : type(string)
        flatten(concat(
          [
            for not_scope in config.not_scopes :
            try(var.policy_injected_variables[substr(not_scope, 2, length(not_scope) - 3)], "'${not_scope}' NOT_FOUND")
            if length(regexall("^\\$\\[[a-zA-Z_0-9]*\\]$", not_scope)) == 1
          ],
          [
            for not_scope in config.not_scopes :
            not_scope
            if length(regexall("^\\$\\[[a-zA-Z_0-9]*\\]$", not_scope)) == 0
          ]
        ))
      )

    } if config.enabled == true
  }

}

