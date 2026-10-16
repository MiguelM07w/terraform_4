# La suscripción se toma de la variable de entorno ARM_SUBSCRIPTION_ID y la
# autenticación de la sesión de Azure CLI; ninguno de los dos se versiona.
provider "azurerm" {
  features {
    resource_group {
      # Impide borrar el grupo de recursos si contiene recursos no gestionados
      # por este proyecto (los de las capas 02 y 03).
      prevent_deletion_if_contains_resources = true
    }
  }

  # Los proveedores de recursos requeridos ya están registrados en la suscripción.
  resource_provider_registrations = "none"
}
