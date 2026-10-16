resource "azurerm_private_dns_zone" "this" {
  name                = var.name
  resource_group_name = var.resource_group_name
  tags                = var.tags
}

# Los registros A de los Private Endpoints no se declaran aquí: los administra
# el private_dns_zone_group de cada endpoint.
resource "azurerm_private_dns_zone_virtual_network_link" "this" {
  for_each = var.virtual_network_links

  name                 = each.value.name
  private_dns_zone_id  = azurerm_private_dns_zone.this.id
  virtual_network_id   = each.value.virtual_network_id
  registration_enabled = each.value.registration_enabled
  tags                 = var.tags
}
