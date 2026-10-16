output "id" {
  description = "ID de la zona DNS privada."
  value       = azurerm_private_dns_zone.this.id
}

output "name" {
  description = "Nombre de la zona DNS privada."
  value       = azurerm_private_dns_zone.this.name
}

output "virtual_network_link_ids" {
  description = "IDs de los vínculos con redes virtuales, indexados por alias."
  value       = { for k, l in azurerm_private_dns_zone_virtual_network_link.this : k => l.id }
}
