# Adopción de los servicios de datos creados previamente desde el portal (ADR-001).
# Una vez importados en el estado, estos bloques se retiran para que el
# proyecto pueda desplegar un entorno nuevo desde cero.

locals {
  rg_id = "/subscriptions/${data.azurerm_client_config.current.subscription_id}/resourceGroups/${local.resource_group_name}"
}

import {
  to = azurerm_postgresql_flexible_server.this
  id = "${local.rg_id}/providers/Microsoft.DBforPostgreSQL/flexibleServers/${var.postgresql.name}"
}

import {
  to = azurerm_postgresql_flexible_server_active_directory_administrator.this
  id = "${local.rg_id}/providers/Microsoft.DBforPostgreSQL/flexibleServers/${var.postgresql.name}/administrators/${local.postgresql_entra_administrator.object_id}"
}

import {
  to = azurerm_storage_account.this
  id = "${local.rg_id}/providers/Microsoft.Storage/storageAccounts/${var.storage_account.name}"
}

import {
  to = module.pe_blob.azurerm_private_endpoint.this
  id = "${local.rg_id}/providers/Microsoft.Network/privateEndpoints/${var.storage_account.private_endpoint.name}"
}
