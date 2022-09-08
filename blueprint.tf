

resource "azurerm_management_group" "root" {
  display_name = "acfroot-dev"
}

resource "azurerm_management_group" "management" {
  display_name               = "management"
  parent_management_group_id = azurerm_management_group.root.id
}

resource "azurerm_management_group" "solution" {
  display_name               = "solution"
  parent_management_group_id = azurerm_management_group.root.id
}

resource "azurerm_management_group" "sandbox" {
  display_name               = "sandbox"
  parent_management_group_id = azurerm_management_group.root.id
}



module "policy_provisioner" {
  source = "./policy_provisioner"

  use_displayname                = false
  root_deployment_scope_mgm_name = azurerm_management_group.root.name
  custom_policy_definition_path  = "./.config/azure_policy/dev"
  default_assignment_location    = "westeurope"

  mangagement_group_scopes = [
    azurerm_management_group.root.display_name
  ]


  policy_injected_variables = {
    single_injected_value = "This is inserted dynamically"
    list_injected_values = [
      "This values are inserted dynamically",
      "This values are inserted dynamically",
      "This values are inserted dynamically",
      "This values are inserted dynamically"
    ]
  }

}
