output "id" {
  description = "ID del Private Endpoint."
  value       = azurerm_private_endpoint.this.id
}

output "private_ip_address" {
  description = "IP privada asignada al endpoint."
  value       = azurerm_private_endpoint.this.private_service_connection[0].private_ip_address
}

output "network_interface_id" {
  description = "ID de la NIC del endpoint."
  value       = azurerm_private_endpoint.this.network_interface[0].id
}
