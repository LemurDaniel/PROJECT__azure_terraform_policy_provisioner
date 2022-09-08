output "deployed_policy_defintions" {
  value = {
    paths = local.custom_policy_definition_filepaths_from_json
  }
}

output "deployed_policy_set_defintions" {
  value = {
    paths = local.custom_policy_set_definition_filepaths_from_json
  }
}

output "custom_policy_assignment_dataset_from_json" {
  value = local.custom_policy_assignment_dataset_from_json
}

output "list_of_associated_polices" {
  value = local.list_of_associated_polices
}
