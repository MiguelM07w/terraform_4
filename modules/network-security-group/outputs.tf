output "id" {
  description = "ID del NSG."
  value       = azurerm_network_security_group.this.id
}

output "name" {
  description = "Nombre del NSG."
  value       = azurerm_network_security_group.this.name
}

output "rule_ids" {
  description = "IDs de las reglas de seguridad, indexados por nombre."
  value       = { for k, r in azurerm_network_security_rule.this : k => r.id }
}
