output "resource_group_name" {
  description = "Grupo de recursos del estado remoto."
  value       = azurerm_resource_group.tfstate.name
}

output "storage_account_name" {
  description = "Cuenta de almacenamiento del estado remoto."
  value       = azurerm_storage_account.tfstate.name
}

output "container_name" {
  description = "Contenedor de los archivos de estado."
  value       = azurerm_storage_container.tfstate.name
}

output "backend_config" {
  description = "Valores para los archivos env/<entorno>.backend.hcl de los demás proyectos."
  value = {
    resource_group_name  = azurerm_resource_group.tfstate.name
    storage_account_name = azurerm_storage_account.tfstate.name
    container_name       = azurerm_storage_container.tfstate.name
    use_azuread_auth     = true
  }
}
