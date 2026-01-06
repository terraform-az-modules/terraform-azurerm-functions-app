##----------------------------------------------------------------------------- 
## Local declaration
##-----------------------------------------------------------------------------
locals {
  is_windows   = var.kind == "Windows"
  function_app = local.is_windows ? azurerm_windows_function_app.main[0] : azurerm_linux_function_app.main[0]
  name         = var.custom_name != null ? var.custom_name : module.labels.id

  storage_account_name = split("/", var.storage_account_id)[length(split("/", var.storage_account_id)) - 1]

  # Auto assign Key Vault reference identity
  identity_ids = concat(compact([var.key_vault_reference_identity_id]), var.identity_ids)

  dotnet_application_stack          = var.application_stack_dotnet_version != null ? [0] : []
  java_application_stack            = var.application_stack_java_version != null ? [0] : []
  node_application_stack            = var.application_stack_node_version != null ? [0] : []
  python_application_stack          = var.application_stack_python_version != null ? [0] : []
  powershell_core_application_stack = var.application_stack_powershell_core_version != null ? [0] : []
}
