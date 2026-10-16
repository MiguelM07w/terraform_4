output "id" {
  description = "ID de la red virtual."
  value       = azurerm_virtual_network.this.id
}

output "name" {
  description = "Nombre de la red virtual."
  value       = azurerm_virtual_network.this.name
}

output "address_space" {
  description = "Espacios de direcciones de la red virtual."
  value       = azurerm_virtual_network.this.address_space
}

output "subnet_ids" {
  description = "IDs de las subredes, indexados por alias."
  value       = { for k, s in azurerm_subnet.this : k => s.id }
}

output "subnet_names" {
  description = "Nombres de las subredes, indexados por alias."
  value       = { for k, s in azurerm_subnet.this : k => s.name }
}

output "subnet_address_prefixes" {
  description = "Bloques CIDR de las subredes, indexados por alias."
  value       = { for k, s in azurerm_subnet.this : k => s.address_prefixes }
}
