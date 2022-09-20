## Implementation of a Policy Provisioner for Azure via Terraform
Got great feedback from Teamlead and meant I'm allowed to share it on my personal git, so leaving it here.

### Module Usage:

```terraform
module "policy_provisioner" {
   source = "./policy_provisioner"

   // Switch between usage of assignment name or Displayname as definied in *.parameters.json
   // False always uses the filename as the Policy-Definition Name
   use_displayname                = false
   // The Root Management Group, where Policy-Definitions and PolicySet-Definitions are deployed.
   root_deployment_scope_mgm_name = azurerm_management_group.root.name
   // Path to the Folder containing all Policy-Definitions, PolicySet-Definitions and Policy-Assignments.
   custom_policy_definition_path  = "./.config/azure_policy/dev"
   // The default assignment location. (For DeployIfNotExists and Modify Policies)
   default_assignment_location    = "westeurope"

   // List of management group for the Policy-Assignments.
   // (Each must have a corresponding <management_group_name>.assignments.json)
   mangagement_group_scopes = [
    azurerm_management_group.root.display_name
   ]

   // Map of Variables that are dynamically injected into Policy-Assignment Parameters.
   // Only one layer of Depth and Variables are only meant to have a single value or a list of single values. 
   policy_injected_variables = {
    single_injected_value = "This is inserted dynamically"
    list_injected_values = [
      "These values are inserted dynamically1",
      "These values are inserted dynamically2",
      "These values are inserted dynamically3",
      "These values are inserted dynamically4"
    ]
  }
}
```

---

### **Policy Assignments**

Policy-Assignments are done via the `<management_group_name>.assignments.json`-Files. Each Mangament-Group has a corresponding file.

#### **Structure of `<management_group_name>.assignments.json`**
>```jsonc
>{
>  "App Service": [],
>  "Automation": [],
>  "Backup": [],
>  "Compute": [],
>  "Tags": [
>     {
>      // Enable/Disable Policy-Assignment
>      "enabled": true,
>      // Corresponds to the filename of either a Policy-Definition or PolicySet-Definition
>      "associated_policy": "deny-without-mandatory-tags",
>      // The Name of the Policy/PolicySet-Assignment
>      "assignment_name": "deny-wo-man-tags",
>      "description": "optional",
>      "location": "optional",
>      // Any Subsequent Paramets passed down to the Policy.
>      "parameters": {
>        "effect": "Deny",
>        "ExcludedVmNamePatterns": [
>          "Preparati*",
>          // Dynamically Appending a list of values as defined in module
>          // The Pattern is $[<Variable name under 'policy_injected_variables'-Key>]
>          "$[list_injected_values]"
>        ],
>        // Inject a single Value dynamically.
>        // The Pattern is $[<Variable name under 'policy_injected_variables'-Key>]
>        "AnotherValue": "$[single_injected_value]"
>          // Only single replacements possible, not "bla-$[single_injected_value]-$[single_injected_value]-test"
>          // (Maybe improvements in the Future, more sophistication not required as of yet)
>      },
>      // A list of Not-Scopes for the Policy.
>      "not_scopes": [
>        // dynamically appending lists also works for not_scopes
>        "/providers/Microsoft.Management/managementGroups/sandbox-dev"
>      ]
>    }
>  ]
>}
>
>```
>

---

### **Defining Policies**

!NOTE!: 
Each Policy-Definition is in an additional Sub-Folder, whose name gets set as the 'category'-Metadata on each Policy. The Structure itself isn't releveant for the `*.assignment.json` or `*.initiative.json`-Files. Any Subsequent Subfolder is ignored by the Policy-Provisioner and only Relevant for the User to Structure them easily. Like Grouping Policies, that are part of an initiatvie, in a shared subfolder like => `Priviledges/deny-priv-elevation`
  

Policy-Definition are stored under the 'custom_policy_definition_path' in the 'policy_definitions'-Folder
Each Policy-Definition consits of a `<name>.paramters.json*` and a corresponding `<name>.rules.json`

#### **Structure of `<name>.paramters.json`**
>Defines all the Metadata and Parameters of a Policy-Definition as follows:
>```jsonc
>{
>    "displayName": "(Optional) The Policy-Definition Displayname",
>    "description": "(Optional) A general Description of the Policy-Definition",
>    "mode": "(Optional) defaults to Indexed",
>    // If this key is missing, the parameters and rules are evaluted for modify or DeployIfNotExists 
>    // Requires the use the parameter_name 'effect' if policy effect is not hardcoded.
>    "managedIdentity": "(Optional) Defaults to 'SystemAssigned' on Modify and DeployIfNotExists Policies",
>    "parameters": {
>        "location": {
>            "type": "String",
>            "metadata": {
>                "displayName": "Location (Specifies a location)",
>                "description": "Sepcifies a location",
>            },
>            "allowedValues": [
>                "westeurope",
>                "germanywestcentral"
>            ],
>            "defaultValue": "westeurope"
>        },
>        "effect": {
>            "type": "String",
>            "defaultValue": "auditIfNotExists"
>        }
>        .
>        .
>        . 
>        etc.
>    }
>}
>```
>

#### **Structure of `<name>.rules.json`**
>Defines the Rule of a Polciy-Definition.
>```jsonc
>{
>    "if": {
>        "allOf": [
>            {
>                "field": "type",
>                "notIn": [
>                    "Microsoft.Compute/virtualMachines/extensions",
>                    "microsoft.insights/workbooks",
>                    "Microsoft.Network/firewallPolicies",
>                    "Microsoft.OperationsManagement/solutions"
>                ]
>            },
>            {
>                "field": "name",
>                "notLike": "AzureBackupRG_*"
>            },
>            {
>                "value": "[length(resourceGroup().tags[parameters('tagName')])]",
>                "notEquals": 0
>            },
>            {
>                "field": "[concat('tags[', parameters('tagName'), ']')]",
>                "notEquals": "[resourceGroup().tags[parameters('tagName')]]"
>            }
>        ]
>    },
>    "then": {
>        "effect": "modify",
>        "details": {
>            // Role Definitions specified here are used for assignment by the Policy-Provisioner.
>            // If none is specifed, the Provisioner defaults to Contributor Permissions.
>            "roleDefinitionIds": [
>                "/providers/microsoft.authorization/roleDefinitions/b24988ac-6180-42a0-ab88-20f7382dd24c"
>            ],
>            "operations": [
>                {
>                    "operation": "addOrReplace",
>                    "field": "[concat('tags[', parameters('tagName'), ']')]",
>                    "value": "[resourceGroup().tags[parameters('tagName')]]"
>                }
>            ]
>        }
>    }
>}
>```
>

---

### **Defining Initiatives**

PolicySet-Definitions are stored under the 'custom_policy_definition_path' in the 'policy_set_definitions'-Folder
Each PolicySet-Definition consits of a `<name>.parameters.json` and a corresponding `<name>.initiative.json`

#### **Structure of `<name>.paramters.json`**
>Like the Policy-Definition, these hold all the Metadata and Parameters for a PolicySet-Definition as follows:
>```jsonc
>{
>    "displayName": "(Optional) inherit-tags",
>    "description": "(Optional)",
>    "managedIdentity": "(Required for Modify and DeployIfNotExists Policies)",
>    "roleDefinitionIds": [
>        // (Required for Modify and DeployIfNotExists Policies)
>        "/providers/microsoft.authorization/roleDefinitions/b24988ac-6180-42a0-ab88-20f7382dd24c"
>    ],
>    "parameters": {}
>}
>```

#### **Structure of `<name>.paramters.json`**
>These hold all the Policies, that are Part of the Set, and pass down any Parameters
>```jsonc
>[
>    {
>        "policyDefinitionName": "inherit-accountable",
>        "policyReferenceId": "inherit-accountable",
>        "parameters": {
>            "tagName": {
>                "value": "govAccountable"
>            }
>        }
>    },
>    {
>        "policyDefinitionName": "inherit-responsible",
>        "policyReferenceId": "inherit-responsible",
>        "parameters": {
>            "tagName": {
>                "value": "govResponsible"
>            }
>        }
>    }
>    .
>    .
>    .
>    etc.
>}
>```
>
