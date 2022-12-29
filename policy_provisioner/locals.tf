

locals {

  root_deployment_scope = "/providers/Microsoft.Management/managementGroups/${var.root_deployment_scope_mgm_name}"

  # Library path to policy definitions.
  custom_policy_assignments_library_path    = abspath(format("%s/%s/%s", path.root, var.custom_policy_definition_path, "policy_assignments"))
  custom_policy_definition_library_path     = abspath(format("%s/%s/%s", path.root, var.custom_policy_definition_path, "policy_definitions"))
  custom_policy_set_definition_library_path = abspath(format("%s/%s/%s", path.root, var.custom_policy_definition_path, "policy_set_definitions"))


  # Load policy definition '.assignment' json files.
  custom_policy_assignment_dataset_from_json = {
    for filepath in fileset(local.custom_policy_assignments_library_path, "*.assignments.json") :
    filepath => flatten([
      for category, assignments in jsondecode(file("${local.custom_policy_assignments_library_path}/${filepath}")) :
      [for assignment in assignments : merge(assignment, { category : category })]
    ])
  }

  # Retrieve non-custom policy reference for data-read.
  list_of_associated_polices = toset(
    flatten(values(local.custom_policy_assignment_dataset_from_json))[*].associated_policy
  )

  /*
  list_of_built_in_policy_references = {
    for associated_policy in local.list_of_associated_polices :
    associated_policy => split("/", associated_policy)[length(split("/", associated_policy)) - 1]
    if length(regexall("^/providers/microsoft[.]authorization/policydefinitions/*", lower(associated_policy))) > 0
  }
  */

  /*
  list_of_built_in_policy_set_references = {
    for associated_policy in local.list_of_associated_polices :
    associated_policy => split("/", associated_policy)[length(split("/", associated_policy)) - 1]
    if length(regexall("^/providers/microsoft[.]authorization/policysetdefinitions/*", lower(associated_policy))) > 0
  }
  */
}

#######################################################################################
#################            handle policy defintions              ####################
#######################################################################################

locals {

  # Load policy definition '.initiative' json files.
  custom_policy_definition_parameter_dataset_from_json = {
    for filepath in fileset(local.custom_policy_definition_library_path, "**/*.parameters.json") :
    replace(split(".", filepath)[0], " ", "_") => jsondecode(templatefile("${local.custom_policy_definition_library_path}/${filepath}", {}))
  }

  # Load policy definition '.rules' json files.
  custom_policy_definition_rules_dataset_from_json = {
    for filepath in fileset(local.custom_policy_definition_library_path, "**/*.rules.json") :
    replace(split(".", filepath)[0], " ", "_") => jsondecode(templatefile("${local.custom_policy_definition_library_path}/${filepath}", {}))
  }

  # Merge all found filepaths ==> This way terraform will fail if only a rules.json or a parameters.json has been defined without the respective other.
  custom_policy_definition_filepaths_from_json = setunion(
    keys(local.custom_policy_definition_parameter_dataset_from_json),
    keys(local.custom_policy_definition_rules_dataset_from_json)
  )


  # Final Dataset of all policy Definitions
  custom_policy_definitions_dataset_full = {
    for filepath in local.custom_policy_definition_filepaths_from_json :
    split("/", filepath)[length(split("/", filepath)) - 1] => {
      mode        = lookup(local.custom_policy_definition_parameter_dataset_from_json[filepath], "mode", "Indexed")
      description = lookup(local.custom_policy_definition_parameter_dataset_from_json[filepath], "description", "")
      displayName = lookup(local.custom_policy_definition_parameter_dataset_from_json[filepath], "displayName", null)
      name        = split("/", filepath)[length(split("/", filepath)) - 1]
      policy_type = "Custom"

      roleDefinitionIds = try(local.custom_policy_definition_rules_dataset_from_json[filepath].then.details.roleDefinitionIds, [])

      rules = local.custom_policy_definition_rules_dataset_from_json[filepath]
      parameters = {
        for parameter_name, parameter_value in local.custom_policy_definition_parameter_dataset_from_json[filepath].parameters :
        parameter_name => merge({
          metadata = {
            displayName = parameter_name,
            description = parameter_name
          }
          },
          parameter_value
        )
      }

      managedIdentity = lookup(local.custom_policy_definition_parameter_dataset_from_json[filepath], "managedIdentity",
        contains(["modify", "deployifnotexists"],
          lower(
            try(
              local.custom_policy_definition_parameter_dataset_from_json[filepath].parameters.effect.defaultValue,
              local.custom_policy_definition_rules_dataset_from_json[filepath].then.effect
            )
          )
        ) == true ? "SystemAssigned" : null
      )

      metadata = {
        "category" : format("ACF-%s", replace(split("/", filepath)[0], "_", " "))
      }
    }
  }
}


#######################################################################################
#################          handle policy set defintions            ####################
#######################################################################################

locals {

  # Load policy set definition '.parameters' json files.
  custom_policy_set_definition_parameter_dataset_from_json = {
    for filepath in fileset(local.custom_policy_set_definition_library_path, "*/*.parameters.json") :
    split(".", filepath)[0] => jsondecode(templatefile("${local.custom_policy_set_definition_library_path}/${filepath}", {}))
  }
  # Load policy set definition '.initiative' json files.
  custom_policy_set_definition_references_dataset_from_json = {
    for filepath in fileset(local.custom_policy_set_definition_library_path, "*/*.initiative.json") :
    split(".", filepath)[0] => jsondecode(templatefile("${local.custom_policy_set_definition_library_path}/${filepath}", {}))
  }

  # Merge all found filepaths ==> This way terraform will fail if only a rules.json or a parameters.json has been defined without the respective other.
  custom_policy_set_definition_filepaths_from_json = setunion(
    keys(local.custom_policy_set_definition_parameter_dataset_from_json),
    keys(local.custom_policy_set_definition_references_dataset_from_json)
  )


  # Final Dataset of all policy set definitions
  custom_policy_set_definitions_dataset_full = {
    for filepath in local.custom_policy_set_definition_filepaths_from_json :
    split("/", filepath)[1] => {
      description = local.custom_policy_set_definition_parameter_dataset_from_json[filepath].description
      displayName = local.custom_policy_set_definition_parameter_dataset_from_json[filepath].displayName
      name        = split("/", filepath)[1]
      policy_type = "Custom"

      managedIdentity   = lookup(local.custom_policy_set_definition_parameter_dataset_from_json[filepath], "managedIdentity", null)
      roleDefinitionIds = lookup(local.custom_policy_set_definition_parameter_dataset_from_json[filepath], "roleDefinitionIds", [])

      policy_references = local.custom_policy_set_definition_references_dataset_from_json[filepath]
      parameters = {
        for parameter_name, parameter_value in local.custom_policy_set_definition_parameter_dataset_from_json[filepath].parameters :
        parameter_name => merge({
          metadata = {
            displayName = parameter_name,
            description = parameter_name
          }
          },
          parameter_value
        )
      }

      metadata = {
        "category" : format("ACF-%s", replace(split("/", filepath)[0], "_", " "))
      }
    }
  }
}
