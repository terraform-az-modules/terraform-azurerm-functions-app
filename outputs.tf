##-----------------------------------------------------------------------------
## Outputs
##-----------------------------------------------------------------------------

output "identity" {
  value = [
    for id in azurerm_linux_function_app.main[0].identity : {
      principal_id = id.principal_id
      type         = id.type
    }
  ]
}

output "function_app_name" {
  value = local.is_windows ? azurerm_windows_function_app.main[0].name : azurerm_linux_function_app.main[0].name
}

output "function_app_id" {
  value = local.is_windows ? azurerm_windows_function_app.main[0].id : azurerm_linux_function_app.main[0].id
}


