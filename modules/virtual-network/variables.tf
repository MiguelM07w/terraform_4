variable "name" {
  description = "Nombre de la red virtual."
  type        = string
}

variable "location" {
  description = "Región de Azure de la red virtual."
  type        = string
}

variable "resource_group_name" {
  description = "Grupo de recursos donde se crea la red virtual."
  type        = string
}

variable "address_space" {
  description = "Espacios de direcciones (CIDR) de la red virtual."
  type        = list(string)

  validation {
    condition     = alltrue([for cidr in var.address_space : can(cidrhost(cidr, 0))])
    error_message = "Cada elemento de address_space debe ser un bloque CIDR válido."
  }
}

variable "subnets" {
  description = <<-EOT
    Subredes de la red virtual, indexadas por un alias estable (por ejemplo, "app").
    - name: nombre de la subred en Azure.
    - address_prefixes: bloques CIDR de la subred.
    - default_outbound_access_enabled: acceso implícito a Internet (desactivado = subred privada).
    - private_endpoint_network_policies: Disabled | Enabled | NetworkSecurityGroupEnabled | RouteTableEnabled.
    - delegation: delegación opcional a un servicio de Azure.
  EOT
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
  default = {}

  validation {
    condition = alltrue([
      for s in values(var.subnets) : contains(
        ["Disabled", "Enabled", "NetworkSecurityGroupEnabled", "RouteTableEnabled"],
        s.private_endpoint_network_policies
      )
    ])
    error_message = "private_endpoint_network_policies debe ser Disabled, Enabled, NetworkSecurityGroupEnabled o RouteTableEnabled."
  }

  validation {
    condition     = alltrue(flatten([for s in values(var.subnets) : [for cidr in s.address_prefixes : can(cidrhost(cidr, 0))]]))
    error_message = "Cada address_prefix de las subredes debe ser un bloque CIDR válido."
  }
}

variable "tags" {
  description = "Etiquetas de la red virtual."
  type        = map(string)
  default     = {}
}
