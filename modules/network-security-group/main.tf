resource "azurerm_network_security_group" "this" {
  name                = var.name
  location            = var.location
  resource_group_name = var.resource_group_name
  tags                = var.tags
}

# Cada regla es un recurso independiente: el plan muestra con precisión qué
# regla cambia y se evita reescribir el conjunto completo en cada cambio.
resource "azurerm_network_security_rule" "this" {
  for_each = var.security_rules

  name                         = each.key
  resource_group_name          = var.resource_group_name
  network_security_group_name  = azurerm_network_security_group.this.name
  description                  = each.value.description
  priority                     = each.value.priority
  direction                    = each.value.direction
  access                       = each.value.access
  protocol                     = each.value.protocol
  source_port_range            = each.value.source_port_range
  destination_port_range       = each.value.destination_port_range
  destination_port_ranges      = each.value.destination_port_ranges
  source_address_prefix        = each.value.source_address_prefix
  source_address_prefixes      = each.value.source_address_prefixes
  destination_address_prefix   = each.value.destination_address_prefix
  destination_address_prefixes = each.value.destination_address_prefixes
}

resource "azurerm_subnet_network_security_group_association" "this" {
  for_each = var.subnet_ids

  subnet_id                 = each.value
  network_security_group_id = azurerm_network_security_group.this.id

  # Las reglas deben existir antes de aplicar el NSG a la subred para no
  # dejarla, ni por un momento, solo con las reglas predeterminadas.
  depends_on = [azurerm_network_security_rule.this]
}
