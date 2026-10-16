terraform {
  required_version = ">= 1.11.0"

  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 5.10"
    }
  }

  # Configuración parcial: los valores se proporcionan con
  # `terraform init -backend-config=env/<entorno>.backend.hcl`.
  # La primera ejecución usa un backend local temporal (ver README).
  backend "azurerm" {}
}
