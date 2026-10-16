output "web_app_name" {
  description = "Nombre de la Web App."
  value       = azurerm_linux_web_app.this.name
}

output "web_app_url" {
  description = "URL pública de la Web App (flujo 1)."
  value       = "https://${azurerm_linux_web_app.this.default_hostname}"
}

output "web_app_principal_id" {
  description = "Object ID de la identidad administrada de la Web App."
  value       = azurerm_linux_web_app.this.identity[0].principal_id
}

output "vm_name" {
  description = "Nombre de la VM worker."
  value       = azurerm_linux_virtual_machine.worker.name
}

output "vm_private_ip_address" {
  description = "IP privada de la VM worker."
  value       = azurerm_network_interface.worker.private_ip_address
}

output "vm_principal_id" {
  description = "Object ID de la identidad administrada de la VM worker."
  value       = azurerm_linux_virtual_machine.worker.identity[0].principal_id
}

output "bastion_name" {
  description = "Nombre del Bastion para conectarse a la VM desde el portal."
  value       = azurerm_bastion_host.this.name
}
