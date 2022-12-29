output "deployed_policy_defintions" {
  description = "Outputs deployed policy definitions file paths. Mainly for debugging."
  value = {
    paths = local.custom_policy_definition_filepaths_from_json
  }
}

output "deployed_policy_set_defintions" {
  description = "Outputs deployed policy set definitions file paths. Mainly for debugging."
  value = {
    paths = local.custom_policy_set_definition_filepaths_from_json
  }
}

output "custom_policy_assignment_dataset_from_json" {
  description = "Outputs custom policy assignments dataset. Mainly for debugging."
  value       = local.custom_policy_assignment_dataset_from_json
}

output "list_of_associated_polices" {
  description = "Outputs list of associated policies. Mainly for debugging."
  value       = local.list_of_associated_polices
}

output "policy_injected_variables" {
  description = "Outputs policy injected variables. Mainly for debugging."
  value       = var.policy_injected_variables
}
