output "resource_group_name" {
  description = "Grupo de recursos de la carga de trabajo."
  value       = azurerm_resource_group.this.name
}

output "resource_group_id" {
  description = "ID del grupo de recursos de la carga de trabajo."
  value       = azurerm_resource_group.this.id
}

output "location" {
  description = "Región de los recursos de la carga de trabajo."
  value       = var.location
}

output "tags" {
  description = "Etiquetas comunes que heredan las capas superiores."
  value       = var.tags
}

output "vnet_id" {
  description = "ID de la red virtual."
  value       = module.vnet.id
}

output "vnet_name" {
  description = "Nombre de la red virtual."
  value       = module.vnet.name
}

output "subnet_ids" {
  description = "IDs de las subredes, indexados por alias."
  value       = module.vnet.subnet_ids
}

output "subnet_address_prefixes" {
  description = "Bloques CIDR de las subredes, indexados por alias."
  value       = module.vnet.subnet_address_prefixes
}

output "network_security_group_ids" {
  description = "IDs de los NSG, indexados por el alias de su subred."
  value       = { for alias, nsg in module.nsg : alias => nsg.id }
}

output "private_dns_zone_ids" {
  description = "IDs de las zonas DNS privadas, indexados por alias."
  value       = { for alias, zone in module.private_dns_zone : alias => zone.id }
}
