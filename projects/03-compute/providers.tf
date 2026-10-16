# La suscripción se toma de la variable de entorno ARM_SUBSCRIPTION_ID y la
# autenticación de la sesión de Azure CLI; ninguno de los dos se versiona.
provider "azurerm" {
  features {
    virtual_machine {
      # El disco del sistema operativo pertenece al ciclo de vida de la VM.
      delete_os_disk_on_deletion = true
    }
  }

  # Los proveedores de recursos requeridos ya están registrados en la suscripción.
  resource_provider_registrations = "none"
}
