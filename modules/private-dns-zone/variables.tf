variable "name" {
  description = "Nombre de la zona DNS privada (por ejemplo, privatelink.blob.core.windows.net)."
  type        = string
}

variable "resource_group_name" {
  description = "Grupo de recursos donde se crea la zona."
  type        = string
}

variable "virtual_network_links" {
  description = <<-EOT
    Vínculos de la zona con redes virtuales, indexados por un alias estable.
    registration_enabled solo se habilita en zonas de registro automático de VM,
    nunca en zonas privatelink.*.
  EOT
  type = map(object({
    name                 = string
    virtual_network_id   = string
    registration_enabled = optional(bool, false)
  }))
  default = {}
}

variable "tags" {
  description = "Etiquetas de la zona y de sus vínculos."
  type        = map(string)
  default     = {}
}
