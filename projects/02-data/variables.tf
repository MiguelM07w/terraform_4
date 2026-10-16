variable "remote_state" {
  description = "Backend donde se leen las salidas de la capa 01-network."
  type = object({
    resource_group_name  = string
    storage_account_name = string
    container_name       = string
    network_key          = string
  })
}

variable "postgresql" {
  description = "Configuración de Azure Database for PostgreSQL Flexible Server y su Private Endpoint."
  type = object({
    name                         = string
    version                      = string
    sku_name                     = string
    zone                         = string
    storage_mb                   = number
    storage_tier                 = string
    auto_grow_enabled            = optional(bool, false)
    backup_retention_days        = optional(number, 7)
    geo_redundant_backup_enabled = optional(bool, false)
    administrator_login          = string
    password_auth_enabled        = optional(bool, false)
    private_endpoint = object({
      name                   = string
      network_interface_name = string
    })
  })

  validation {
    condition     = var.postgresql.backup_retention_days >= 7 && var.postgresql.backup_retention_days <= 35
    error_message = "La retención de respaldos debe estar entre 7 y 35 días."
  }
}

variable "postgresql_administrator_password" {
  description = "Contraseña del administrador local de PostgreSQL; solo aplica si postgresql.password_auth_enabled = true. Es efímera y de solo escritura: nunca se guarda en el estado. Se proporciona con TF_VAR_postgresql_administrator_password."
  type        = string
  default     = null
  sensitive   = true
  ephemeral   = true
}

variable "postgresql_administrator_password_version" {
  description = "Versión de la contraseña del administrador. Incrementarla junto con la contraseña provoca su rotación."
  type        = number
  default     = null
}

variable "postgresql_entra_administrator" {
  description = "Administrador de Entra ID del servidor. Si es null, se usa el usuario que ejecuta Terraform."
  type = object({
    object_id      = string
    principal_name = string
    principal_type = string
  })
  default = null

  validation {
    condition     = var.postgresql_entra_administrator == null || contains(["User", "Group", "ServicePrincipal"], try(var.postgresql_entra_administrator.principal_type, ""))
    error_message = "principal_type debe ser User, Group o ServicePrincipal."
  }
}

variable "storage_account" {
  description = "Configuración de la cuenta de almacenamiento (Blob) y su Private Endpoint."
  type = object({
    name                     = string
    account_replication_type = optional(string, "LRS")
    access_tier              = optional(string, "Hot")
    blob_retention_days      = optional(number, 7)
    private_endpoint = object({
      name                   = string
      network_interface_name = string
    })
  })

  validation {
    condition     = can(regex("^[a-z0-9]{3,24}$", var.storage_account.name))
    error_message = "El nombre de la cuenta debe tener entre 3 y 24 caracteres, solo minúsculas y números."
  }
}
