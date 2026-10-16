variable "name" {
  description = "Nombre del grupo de seguridad de red."
  type        = string
}

variable "location" {
  description = "Región de Azure del NSG."
  type        = string
}

variable "resource_group_name" {
  description = "Grupo de recursos donde se crea el NSG."
  type        = string
}

variable "security_rules" {
  description = <<-EOT
    Reglas de seguridad indexadas por nombre de regla. Para puertos y prefijos se
    usa la forma singular (destination_port_range) o la plural
    (destination_port_ranges), nunca ambas.
  EOT
  type = map(object({
    priority                     = number
    direction                    = string
    access                       = string
    protocol                     = string
    description                  = optional(string)
    source_port_range            = optional(string, "*")
    destination_port_range       = optional(string)
    destination_port_ranges      = optional(list(string))
    source_address_prefix        = optional(string)
    source_address_prefixes      = optional(list(string))
    destination_address_prefix   = optional(string)
    destination_address_prefixes = optional(list(string))
  }))
  default = {}

  validation {
    condition     = alltrue([for r in values(var.security_rules) : r.priority >= 100 && r.priority <= 4096])
    error_message = "La prioridad de cada regla debe estar entre 100 y 4096."
  }

  validation {
    condition     = alltrue([for r in values(var.security_rules) : contains(["Inbound", "Outbound"], r.direction)])
    error_message = "direction debe ser Inbound u Outbound."
  }

  validation {
    condition     = alltrue([for r in values(var.security_rules) : contains(["Allow", "Deny"], r.access)])
    error_message = "access debe ser Allow o Deny."
  }

  validation {
    condition     = alltrue([for r in values(var.security_rules) : contains(["Tcp", "Udp", "Icmp", "Esp", "Ah", "*"], r.protocol)])
    error_message = "protocol debe ser Tcp, Udp, Icmp, Esp, Ah o *."
  }

  validation {
    condition = length(distinct([
      for r in values(var.security_rules) : "${r.direction}-${r.priority}"
    ])) == length(var.security_rules)
    error_message = "No puede haber dos reglas con la misma prioridad en la misma dirección."
  }
}

variable "subnet_ids" {
  description = "Subredes a las que se asocia el NSG, indexadas por un alias estable."
  type        = map(string)
  default     = {}
}

variable "tags" {
  description = "Etiquetas del NSG."
  type        = map(string)
  default     = {}
}
