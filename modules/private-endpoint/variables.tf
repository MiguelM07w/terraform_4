variable "name" {
  description = "Nombre del Private Endpoint."
  type        = string
}

variable "location" {
  description = "Región de Azure del Private Endpoint (la de la VNet)."
  type        = string
}

variable "resource_group_name" {
  description = "Grupo de recursos donde se crea el Private Endpoint."
  type        = string
}

variable "subnet_id" {
  description = "Subred donde se asigna la IP privada del endpoint."
  type        = string
}

variable "network_interface_name" {
  description = "Nombre de la NIC del endpoint. Si es null, Azure genera uno automáticamente."
  type        = string
  default     = null
}

variable "private_connection_resource_id" {
  description = "ID del recurso PaaS al que se conecta el endpoint."
  type        = string
}

variable "subresource_names" {
  description = "Subrecursos (group IDs) del servicio, por ejemplo [\"blob\"] o [\"postgresqlServer\"]."
  type        = list(string)

  validation {
    condition     = length(var.subresource_names) == 1
    error_message = "Un Private Endpoint se conecta a un único subrecurso."
  }
}

variable "private_service_connection_name" {
  description = "Nombre de la conexión de servicio privada. Por defecto, el nombre del endpoint."
  type        = string
  default     = null
}

variable "private_dns_zone_ids" {
  description = "Zonas DNS privadas donde el endpoint registra automáticamente su registro A."
  type        = list(string)
  default     = []
}

variable "private_dns_zone_group_name" {
  description = "Nombre del grupo de zonas DNS del endpoint."
  type        = string
  default     = "default"
}

variable "tags" {
  description = "Etiquetas del Private Endpoint."
  type        = map(string)
  default     = {}
}
