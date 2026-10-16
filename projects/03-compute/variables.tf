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
