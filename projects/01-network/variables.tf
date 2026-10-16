variable "location" {
  description = "Región de Azure de los recursos de red."
  type        = string
}

variable "resource_group_name" {
  description = "Grupo de recursos de la carga de trabajo, compartido por todas las capas."
  type        = string
}

variable "resource_group_location" {
  description = "Región de los metadatos del grupo de recursos. Puede diferir de var.location: el grupo existente se creó en East US y la ubicación no se puede cambiar sin recrearlo."
  type        = string
}

variable "vnet_name" {
  description = "Nombre de la red virtual."
  type        = string
}

variable "vnet_address_space" {
  description = "Espacio de direcciones de la red virtual."
  type        = list(string)
}

variable "subnets" {
  description = "Subredes de la VNet indexadas por alias (app, db, vm, pe, bastion). Ver el módulo virtual-network."
  type = map(object({
    name                                          = string
    address_prefixes                              = list(string)
    default_outbound_access_enabled               = optional(bool, false)
    private_endpoint_network_policies             = optional(string, "Disabled")
    private_link_service_network_policies_enabled = optional(bool, true)
    service_endpoints                             = optional(list(string), [])
    delegation = optional(object({
      name    = string
      service = string
      actions = list(string)
    }))
  }))

  validation {
    condition     = alltrue([for k in ["app", "db", "vm", "pe", "bastion"] : contains(keys(var.subnets), k)])
    error_message = "Se requieren las subredes con alias app, db, vm, pe y bastion."
  }

  validation {
    condition     = try(var.subnets["bastion"].name, "") == "AzureBastionSubnet"
    error_message = "La subred con alias bastion debe llamarse exactamente AzureBastionSubnet."
  }
}

variable "network_security_groups" {
  description = "Nombre del NSG de cada subred, indexado por el alias de la subred."
  type        = map(string)

  validation {
    condition     = length(setsubtract(keys(var.network_security_groups), ["app", "db", "vm", "pe", "bastion"])) == 0
    error_message = "Los alias de NSG deben corresponder a subredes conocidas: app, db, vm, pe o bastion."
  }
}

variable "private_dns_zones" {
  description = "Zonas DNS privadas de Private Link y nombre de su vínculo con la VNet, indexadas por alias."
  type = map(object({
    name           = string
    vnet_link_name = string
  }))
}

variable "tags" {
  description = "Etiquetas comunes de la carga de trabajo."
  type        = map(string)
  default     = {}
}
