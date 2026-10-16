terraform {
  required_version = ">= 1.11.0"

  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 5.10"
    }
  }

  # Configuración parcial: `terraform init -backend-config=env/<entorno>.backend.hcl`
  backend "azurerm" {}
}
