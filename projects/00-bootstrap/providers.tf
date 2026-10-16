# La suscripción se toma de la variable de entorno ARM_SUBSCRIPTION_ID y la
# autenticación de la sesión de Azure CLI; ninguno de los dos se versiona.
provider "azurerm" {
  features {}

  # Las operaciones de plano de datos sobre Storage usan Entra ID, ya que la
  # cuenta del estado tiene deshabilitadas las llaves de acceso compartidas.
  storage_use_azuread = true

  # Los proveedores de recursos requeridos ya están registrados en la suscripción.
  resource_provider_registrations = "none"
}
