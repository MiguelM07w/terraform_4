data "azurerm_client_config" "current" {}

locals {
  tags = merge(var.tags, {
    iac_layer = "00-bootstrap"
  })
}

resource "azurerm_resource_group" "tfstate" {
  name     = var.resource_group_name
  location = var.location
  tags     = local.tags
}

resource "azurerm_storage_account" "tfstate" {
  name                     = var.storage_account_name
  resource_group_name      = azurerm_resource_group.tfstate.name
  location                 = azurerm_resource_group.tfstate.location
  account_kind             = "StorageV2"
  account_tier             = "Standard"
  account_replication_type = var.storage_replication_type
  access_tier              = "Hot"

  # Seguridad: solo HTTPS con TLS 1.2, autenticación exclusiva con Entra ID
  # y sin acceso anónimo a blobs.
  https_traffic_only_enabled        = true
  min_tls_version                   = "TLS1_2"
  shared_access_key_enabled         = false
  default_to_oauth_authentication   = true
  allow_nested_items_to_be_public   = false
  cross_tenant_replication_enabled  = false
  local_user_enabled                = false
  infrastructure_encryption_enabled = true

  # El acceso público es necesario para operar Terraform desde la estación de
  # trabajo; opcionalmente se restringe a las IP autorizadas. Sin rangos
  # definidos el bloque se omite, ya que Azure no persiste reglas vacías.
  public_network_access = "Enabled"

  dynamic "network_rules" {
    for_each = length(var.allowed_public_ip_ranges) > 0 ? [1] : []

    content {
      default_action = "Deny"
      bypass         = ["AzureServices"]
      ip_rules       = var.allowed_public_ip_ranges
    }
  }

  # Recuperación ante borrados o sobrescrituras accidentales del estado.
  blob_properties {
    versioning_enabled = true

    delete_retention_policy {
      days = var.blob_retention_days
    }

    container_delete_retention_policy {
      days = var.blob_retention_days
    }
  }

  tags = local.tags

  lifecycle {
    prevent_destroy = true
  }
}

resource "azurerm_storage_container" "tfstate" {
  name                  = var.container_name
  storage_account_id    = azurerm_storage_account.tfstate.id
  container_access_type = "private"
}

# El rol Owner no incluye permisos de plano de datos: la identidad que ejecuta
# Terraform necesita este rol para leer y escribir el estado con Entra ID.
resource "azurerm_role_assignment" "tfstate_blob_contributor" {
  scope                = azurerm_storage_account.tfstate.id
  role_definition_name = "Storage Blob Data Contributor"
  principal_id         = data.azurerm_client_config.current.object_id
  description          = "Lectura y escritura del estado remoto de Terraform"
}
