output "postgresql_server_id" {
  description = "ID del servidor PostgreSQL."
  value       = azurerm_postgresql_flexible_server.this.id
}

output "postgresql_server_name" {
  description = "Nombre del servidor PostgreSQL."
  value       = azurerm_postgresql_flexible_server.this.name
}

output "postgresql_fqdn" {
  description = "FQDN del servidor; dentro de la VNet resuelve a la IP del Private Endpoint."
  value       = azurerm_postgresql_flexible_server.this.fqdn
}

output "postgresql_private_ip_address" {
  description = "IP privada del Private Endpoint de PostgreSQL."
  value       = module.pe_postgresql.private_ip_address
}

output "storage_account_id" {
  description = "ID de la cuenta de almacenamiento (ámbito de las asignaciones RBAC)."
  value       = azurerm_storage_account.this.id
}

output "storage_account_name" {
  description = "Nombre de la cuenta de almacenamiento."
  value       = azurerm_storage_account.this.name
}

output "storage_primary_blob_endpoint" {
  description = "Endpoint de Blob; dentro de la VNet resuelve a la IP del Private Endpoint."
  value       = azurerm_storage_account.this.primary_blob_endpoint
}

output "storage_blob_private_ip_address" {
  description = "IP privada del Private Endpoint de Blob."
  value       = module.pe_blob.private_ip_address
}
