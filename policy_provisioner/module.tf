########################################################################################
#################          Policy Definition Deployment             ####################
########################################################################################

resource "azurerm_policy_definition" "custom" {
  for_each = local.custom_policy_definitions_dataset_full

  management_group_id = local.root_deployment_scope

  description  = each.value.description
  display_name = var.use_displayname ? coalesce(each.value.displayName, each.value.name) : each.value.name
  name         = each.value.name
  policy_type  = each.value.policy_type
  mode         = each.value.mode

  metadata    = jsonencode(each.value.metadata)
  policy_rule = jsonencode(each.value.rules)
  parameters  = each.value.parameters != {} ? jsonencode(each.value.parameters) : null

}

########################################################################################
#################        Policy Set Definition Deployment           ####################
########################################################################################

resource "azurerm_policy_set_definition" "custom" {
  for_each = local.custom_policy_set_definitions_dataset_full

  management_group_id = local.root_deployment_scope

  description  = each.value.description
  display_name = var.use_displayname ? coalesce(each.value.displayName, each.value.name) : each.value.name
  name         = each.value.name
  policy_type  = each.value.policy_type

  metadata   = jsonencode(each.value.metadata)
  parameters = each.value.parameters != {} ? jsonencode(each.value.parameters) : null
  # If parameters are empty terraform doesn't store the value. 
  # Setting it to {} will then lead to update on each apply from 'null' => '{}'

  dynamic "policy_definition_reference" {
    for_each = each.value.policy_references

    content {
      policy_definition_id = azurerm_policy_definition.custom[policy_definition_reference.value.policyDefinitionName].id
      parameter_values     = policy_definition_reference.value.parameters != {} ? jsonencode(policy_definition_reference.value.parameters) : null
      reference_id         = policy_definition_reference.value.policyReferenceId
      policy_group_names   = lookup(policy_definition_reference.value, "policy_group_names", null)
    }
  }
}


#######################################################################################
#################      Policy Assignment per Management Group      ####################
#######################################################################################

/*

Momentarily not needed anymore. Policy provisioner creates Id without data-element.

data "azurerm_policy_definition" "built_in" {
  for_each = local.list_of_built_in_policy_references

  name = each.value
}

data "azurerm_policy_set_definition" "built_in" {
  for_each = local.list_of_built_in_policy_set_references

  name = each.value
}

*/

locals {
  policy_assignments_mapping = {
    for management_group in var.mangagement_group_scopes :
    management_group => {

      # Will lead to  Error: Duplicate object key before apply, when two assignments with the same name exist
      for config in local.custom_policy_assignment_dataset_from_json["${management_group}.assignments.json"] :
      config.assignment_name => {

        isBuiltInPolicy = length(
          regexall("/providers/microsoft.authorization/policy",
            lower(lookup(config, "associated_policy", "config.associated_policy_set"))
          )
        ) > 0

        isPolicySet = try(
          local.custom_policy_set_definitions_dataset_full[config.associated_policy] != null,
          length(regexall("policysetdefinition", lower(config.associated_policy))) > 0
        )

        root_deployment_scope = local.root_deployment_scope
        associated_policy     = config.associated_policy

        display_name    = var.use_displayname ? lookup(config, "display_name", config.assignment_name) : config.assignment_name
        assignment_name = config.assignment_name
        description     = lookup(config, "description", "")
        parameters      = config.parameters
        not_scopes      = config.not_scopes

        location = lookup(config, "location", null)

        enforce = lookup(config, "enforce", null)
        enabled = config.enabled

        metadata = {
          "category" : format("ACF-%s", replace(config.category, "_", " "))
        }

        roleDefinitionIds = try(
          try(
            local.custom_policy_definitions_dataset_full[config.associated_policy].roleDefinitionIds,
            local.custom_policy_set_definitions_dataset_full[config.associated_policy].roleDefinitionIds
            # data.azurerm_policy_definition.built_in[config.associated_policy].policy_rule.then.details.roleDefinitionIds
          ),
          []
        )

        managedIdentity = lookup(config, "managedIdentity",
          contains(["modify", "deployifnotexists"], lower(lookup(config.parameters, "effect", ""))) == true ? "SystemAssigned" : (
            try(
              try(
                local.custom_policy_definitions_dataset_full[config.associated_policy].managedIdentity,
                local.custom_policy_set_definitions_dataset_full[config.associated_policy].managedIdentity
              ),
              false
            )
          )
        )

        /*
        associated_policy_id = try(
          try(
            azurerm_policy_definition.custom[config.associated_policy],
            azurerm_policy_set_definition.custom[config.associated_policy]
          ),
          config.associated_policy
        )
        */


      } if config.enabled == true

    }
  }
}

module "policy_assignment" {
  source = "./policy_assignment"

  for_each = local.policy_assignments_mapping

  default_assignment_role_ids = var.default_assignment_role_ids

  default_assignment_location = var.default_assignment_location
  policy_injected_variables   = var.policy_injected_variables

  policy_assignment_scope           = each.key
  policy_assignments_configurations = each.value

  depends_on = [
    azurerm_policy_definition.custom,
    azurerm_policy_set_definition.custom
  ]
}
