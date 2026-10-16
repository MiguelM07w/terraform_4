# Flujos 3 y 5: las identidades administradas acceden a Blob mediante RBAC,
# sin llaves ni SAS (la cuenta tiene deshabilitadas las llaves compartidas).
locals {
  blob_data_contributors = {
    web-app = azurerm_linux_web_app.this.identity[0].principal_id
    worker  = azurerm_linux_virtual_machine.worker.identity[0].principal_id
  }
}

resource "azurerm_role_assignment" "blob_data_contributor" {
  for_each = local.blob_data_contributors

  scope                = local.data.storage_account_id
  role_definition_name = "Storage Blob Data Contributor"
  principal_id         = each.value
  principal_type       = "ServicePrincipal"
  description          = "Acceso de ${each.key} a Blob con su identidad administrada"
}
