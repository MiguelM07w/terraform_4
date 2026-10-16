data "azurerm_client_config" "current" {}

data "terraform_remote_state" "network" {
  backend = "azurerm"

  config = {
    resource_group_name  = var.remote_state.resource_group_name
    storage_account_name = var.remote_state.storage_account_name
    container_name       = var.remote_state.container_name
    key                  = var.remote_state.network_key
    use_azuread_auth     = true
  }
}

# Sin un administrador explícito, se usa el usuario que ejecuta Terraform.
data "azuread_user" "current" {
  count     = var.postgresql_entra_administrator == null ? 1 : 0
  object_id = data.azurerm_client_config.current.object_id
}

locals {
  network = data.terraform_remote_state.network.outputs

  resource_group_name = local.network.resource_group_name
  location            = local.network.location

  tags = merge(local.network.tags, {
    iac_layer = "02-data"
  })

  postgresql_entra_administrator = coalesce(var.postgresql_entra_administrator, {
    object_id      = data.azurerm_client_config.current.object_id
    principal_name = one(data.azuread_user.current[*].user_principal_name)
    principal_type = "User"
  })
}
