resource "azurerm_postgresql_flexible_server" "this" {
  name                = var.postgresql.name
  resource_group_name = local.resource_group_name
  location            = local.location
  version             = var.postgresql.version
  sku_name            = var.postgresql.sku_name
  zone                = var.postgresql.zone

  storage_mb        = var.postgresql.storage_mb
  storage_tier      = var.postgresql.storage_tier
  auto_grow_enabled = var.postgresql.auto_grow_enabled

  backup_retention_days        = var.postgresql.backup_retention_days
  geo_redundant_backup_enabled = var.postgresql.geo_redundant_backup_enabled

  # Solo accesible mediante el Private Endpoint de snet-db.
  public_network_access_enabled = false

  # La contraseña es de solo escritura: no se guarda en el estado ni en el plan.
  administrator_login               = var.postgresql.administrator_login
  administrator_password_wo         = var.postgresql_administrator_password
  administrator_password_wo_version = var.postgresql_administrator_password_version

  # Autenticación exclusiva con Entra ID: el administrador entra con su cuenta
  # y la App y la VM con tokens de sus identidades administradas (flujos 2 y 4).
  authentication {
    active_directory_auth_enabled = true
    password_auth_enabled         = var.postgresql.password_auth_enabled
    tenant_id                     = data.azurerm_client_config.current.tenant_id
  }

  tags = local.tags

  lifecycle {
    prevent_destroy = true

    # El proveedor exige la contraseña en cualquier actualización mientras la
    # autenticación por contraseña esté habilitada; se valida desde el plan.
    precondition {
      condition     = !var.postgresql.password_auth_enabled || var.postgresql_administrator_password_version != null
      error_message = "Con password_auth_enabled = true se requieren TF_VAR_postgresql_administrator_password y postgresql_administrator_password_version."
    }
  }
}

resource "azurerm_postgresql_flexible_server_active_directory_administrator" "this" {
  server_name         = azurerm_postgresql_flexible_server.this.name
  resource_group_name = local.resource_group_name
  tenant_id           = data.azurerm_client_config.current.tenant_id
  object_id           = local.postgresql_entra_administrator.object_id
  principal_name      = local.postgresql_entra_administrator.principal_name
  principal_type      = local.postgresql_entra_administrator.principal_type
}

module "pe_postgresql" {
  source = "../../modules/private-endpoint"

  name                           = var.postgresql.private_endpoint.name
  network_interface_name         = var.postgresql.private_endpoint.network_interface_name
  location                       = local.location
  resource_group_name            = local.resource_group_name
  subnet_id                      = local.network.subnet_ids["db"]
  private_connection_resource_id = azurerm_postgresql_flexible_server.this.id
  subresource_names              = ["postgresqlServer"]
  private_dns_zone_ids           = [local.network.private_dns_zone_ids["postgres"]]
  tags                           = local.tags
}
