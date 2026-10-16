variable "location" {
  description = "Región de Azure donde se despliegan los recursos del estado remoto."
  type        = string
}

variable "resource_group_name" {
  description = "Nombre del grupo de recursos dedicado al estado de Terraform."
  type        = string
}

variable "storage_account_name" {
  description = "Nombre globalmente único de la cuenta de almacenamiento del estado."
  type        = string

  validation {
    condition     = can(regex("^[a-z0-9]{3,24}$", var.storage_account_name))
    error_message = "Debe tener entre 3 y 24 caracteres, solo minúsculas y números."
  }
}

variable "container_name" {
  description = "Nombre del contenedor de blobs que almacena los archivos de estado."
  type        = string
  default     = "tfstate"
}

variable "storage_replication_type" {
  description = "Tipo de replicación de la cuenta del estado."
  type        = string
  default     = "ZRS"

  validation {
    condition     = contains(["LRS", "ZRS", "GRS", "GZRS", "RAGRS", "RAGZRS"], var.storage_replication_type)
    error_message = "Valores permitidos: LRS, ZRS, GRS, GZRS, RAGRS o RAGZRS."
  }
}

variable "blob_retention_days" {
  description = "Días de retención para blobs y contenedores eliminados (recuperación del estado)."
  type        = number
  default     = 30

  validation {
    condition     = var.blob_retention_days >= 1 && var.blob_retention_days <= 365
    error_message = "La retención debe estar entre 1 y 365 días."
  }
}

variable "allowed_public_ip_ranges" {
  description = "Rangos IPv4 públicos (CIDR) autorizados para acceder a la cuenta del estado. Si la lista está vacía, se permite el acceso desde cualquier red y la protección recae en Entra ID."
  type        = list(string)
  default     = []
}

variable "tags" {
  description = "Etiquetas comunes aplicadas a todos los recursos."
  type        = map(string)
  default     = {}
}
