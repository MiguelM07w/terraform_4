# Adopción de los recursos de red creados previamente desde el portal (ADR-001).
# Una vez importados en el estado, estos bloques se retiran para que el
# proyecto pueda desplegar un entorno nuevo desde cero.

locals {
  rg_id   = "/subscriptions/${data.azurerm_client_config.current.subscription_id}/resourceGroups/${var.resource_group_name}"
  vnet_id = "${local.rg_id}/providers/Microsoft.Network/virtualNetworks/${var.vnet_name}"

  # Nombre generado automáticamente por el portal para los vínculos DNS existentes.
  legacy_dns_link_name = "oy7ijpxxwyqr6"
}

import {
  to = azurerm_resource_group.this
  id = local.rg_id
}

import {
  to = module.vnet.azurerm_virtual_network.this
  id = local.vnet_id
}

import {
  for_each = var.subnets
  to       = module.vnet.azurerm_subnet.this[each.key]
  id       = "${local.vnet_id}/subnets/${each.value.name}"
}

import {
  for_each = var.private_dns_zones
  to       = module.private_dns_zone[each.key].azurerm_private_dns_zone.this
  id       = "${local.rg_id}/providers/Microsoft.Network/privateDnsZones/${each.value.name}"
}

import {
  for_each = var.private_dns_zones
  to       = module.private_dns_zone[each.key].azurerm_private_dns_zone_virtual_network_link.this["workload"]
  id       = "${local.rg_id}/providers/Microsoft.Network/privateDnsZones/${each.value.name}/virtualNetworkLinks/${local.legacy_dns_link_name}"
}
