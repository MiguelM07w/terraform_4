resource "azurerm_storage_account" "this" {
  name                     = var.storage_account.name
  resource_group_name      = local.resource_group_name
  location                 = local.location
  account_kind             = "StorageV2"
  account_tier             = "Standard"
  account_replication_type = var.storage_account.account_replication_type
  access_tier              = var.storage_account.access_tier

  https_traffic_only_enabled       = true
  min_tls_version                  = "TLS1_2"
  allow_nested_items_to_be_public  = false
  cross_tenant_replication_enabled = false

  # Autorización exclusiva con Entra ID y RBAC (flujos 3 y 5 del diagrama):
  # se deshabilitan las llaves de acceso compartidas y los SAS firmados con ellas.
  shared_access_key_enabled       = false
  default_to_oauth_authentication = true

  # Solo accesible mediante el Private Endpoint de snet-pe.
  public_network_access = "Disabled"

  network_rules {
    default_action = "Deny"
    bypass         = ["AzureServices"]
  }

  blob_properties {
    versioning_enabled = true

    delete_retention_policy {
      days = var.storage_account.blob_retention_days
    }

    container_delete_retention_policy {
      days = var.storage_account.blob_retention_days
    }
  }

  tags = local.tags

  lifecycle {
    prevent_destroy = true
  }
}

module "pe_blob" {
  source = "../../modules/private-endpoint"

  name                           = var.storage_account.private_endpoint.name
  network_interface_name         = var.storage_account.private_endpoint.network_interface_name
  location                       = local.location
  resource_group_name            = local.resource_group_name
  subnet_id                      = local.network.subnet_ids["pe"]
  private_connection_resource_id = azurerm_storage_account.this.id
  subresource_names              = ["blob"]
  private_dns_zone_ids           = [local.network.private_dns_zone_ids["blob"]]
  tags                           = local.tags
}
