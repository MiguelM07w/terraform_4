# La suscripción se toma de la variable de entorno ARM_SUBSCRIPTION_ID y la
# autenticación de la sesión de Azure CLI; ninguno de los dos se versiona.
provider "azurerm" {
  features {
    storage {
      # La cuenta de almacenamiento no tiene acceso público: el proveedor
      # solo usa el plano de control (ARM) y nunca el plano de datos.
      data_plane_available = false
    }
  }

  storage_use_azuread = true

  # Los proveedores de recursos requeridos ya están registrados en la suscripción.
  resource_provider_registrations = "none"
}

# Se usa únicamente para resolver el UPN del administrador de Entra ID de
# PostgreSQL a partir de la identidad que ejecuta Terraform.
provider "azuread" {}
