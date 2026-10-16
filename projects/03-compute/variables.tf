variable "remote_state" {
  description = "Backend donde se leen las salidas de las capas 01-network y 02-data."
  type = object({
    resource_group_name  = string
    storage_account_name = string
    container_name       = string
    network_key          = string
    data_key             = string
  })
}

variable "app_service" {
  description = "Plan de App Service (Linux) y Web App con integración regional a la VNet."
  type = object({
    plan_name    = string
    sku_name     = string
    worker_count = optional(number, 1)
    web_app_name = string
    node_version = string
    always_on    = optional(bool, false)
  })
}

variable "application_insights_name" {
  description = "Recurso de Application Insights existente que recibe la telemetría de la Web App. Si es null, no se configura la instrumentación."
  type        = string
  default     = null
}

variable "bastion" {
  description = "Azure Bastion para la administración de la VM sin IP pública."
  type = object({
    name = string
    sku  = optional(string, "Developer")
  })

  validation {
    condition     = contains(["Developer", "Basic", "Standard", "Premium"], var.bastion.sku)
    error_message = "El SKU de Bastion debe ser Developer, Basic, Standard o Premium."
  }

  validation {
    condition     = var.bastion.sku == "Developer"
    error_message = "Los SKU dedicados requieren IP pública e ip_configuration en AzureBastionSubnet; este proyecto implementa el SKU Developer (ADR-005)."
  }
}

variable "vm" {
  description = "VM Linux worker sin IP pública."
  type = object({
    name                   = string
    size                   = string
    zone                   = optional(string)
    admin_username         = string
    ssh_public_key_path    = string
    network_interface_name = string
    os_disk_name           = string
    os_disk_type           = optional(string, "StandardSSD_LRS")
    os_disk_size_gb        = optional(number, 30)
    image = object({
      publisher = string
      offer     = string
      sku       = string
      version   = string
    })
  })

  validation {
    condition     = !contains(["admin", "administrator", "root", "azureadmin"], lower(var.vm.admin_username))
    error_message = "El nombre del administrador no puede ser un nombre reservado o predecible."
  }

  validation {
    condition     = contains(["Standard_LRS", "StandardSSD_LRS", "Premium_LRS", "StandardSSD_ZRS", "Premium_ZRS"], var.vm.os_disk_type)
    error_message = "Tipo de disco no soportado."
  }
}
