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

data "terraform_remote_state" "data" {
  backend = "azurerm"

  config = {
    resource_group_name  = var.remote_state.resource_group_name
    storage_account_name = var.remote_state.storage_account_name
    container_name       = var.remote_state.container_name
    key                  = var.remote_state.data_key
    use_azuread_auth     = true
  }
}

locals {
  network = data.terraform_remote_state.network.outputs
  data    = data.terraform_remote_state.data.outputs

  resource_group_name = local.network.resource_group_name
  location            = local.network.location

  tags = merge(local.network.tags, {
    iac_layer = "03-compute"
  })
}
