resource "azurerm_private_endpoint" "this" {
  name                          = var.name
  location                      = var.location
  resource_group_name           = var.resource_group_name
  subnet_id                     = var.subnet_id
  custom_network_interface_name = var.network_interface_name
  tags                          = var.tags

  private_service_connection {
    name                           = coalesce(var.private_service_connection_name, var.name)
    private_connection_resource_id = var.private_connection_resource_id
    subresource_names              = var.subresource_names
    is_manual_connection           = false
  }

  # El grupo de zonas mantiene el registro A sincronizado con la IP del
  # endpoint durante todo su ciclo de vida.
  dynamic "private_dns_zone_group" {
    for_each = length(var.private_dns_zone_ids) > 0 ? [1] : []

    content {
      name                 = var.private_dns_zone_group_name
      private_dns_zone_ids = var.private_dns_zone_ids
    }
  }
}
