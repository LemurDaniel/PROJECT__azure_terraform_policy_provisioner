

resource "azurerm_management_group" "root" {
  display_name = "acfroot"
  name         = "acfroot"
}

resource "azurerm_management_group" "management" {
  display_name               = "management"
  name                       = "management-test"
  parent_management_group_id = azurerm_management_group.root.id
}

resource "azurerm_management_group" "solution" {
  display_name               = "solution"
  name                       = "solution-test"
  parent_management_group_id = azurerm_management_group.root.id
}

resource "azurerm_management_group" "sandbox" {
  display_name               = "sandbox"
  name                       = "sandbox-test"
  parent_management_group_id = azurerm_management_group.root.id
}



module "policy_provisioner" {
  source = "./policy_provisioner"

  use_displayname                = false
  root_deployment_scope_mgm_name = azurerm_management_group.root.name
  custom_policy_definition_path  = "./.config/azure_policy/dev"
  default_assignment_location    = "westeurope"

  mangagement_group_scopes = [
    azurerm_management_group.root.name,
    azurerm_management_group.management.name,
    azurerm_management_group.solution.name,
    azurerm_management_group.sandbox.name
  ]


  policy_injected_variables = {
    single_injected_value = "This is inserted dynamically"
    list_injected_values = [
      "This values are inserted dynamically1",
      "This values are inserted dynamically2",
      "This values are inserted dynamically3",
      "This values are inserted dynamically4"
    ]
  }

}
