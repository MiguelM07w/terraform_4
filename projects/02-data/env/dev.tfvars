remote_state = {
  resource_group_name  = "rg-utvt-tfstate-dev-mxc-001"
  storage_account_name = "sttfutvtintdevmxc001"
  container_name       = "tfstate"
  network_key          = "dev/01-network.tfstate"
}

postgresql = {
  name                = "psql-utvt-integradora-dev-mxc-001-v1"
  version             = "18"
  sku_name            = "B_Standard_B1ms"
  zone                = "1"
  storage_mb          = 32768
  storage_tier        = "P4"
  administrator_login = "adminpgdev"

  private_endpoint = {
    name                   = "pep-utvt-integradora-db-dev-mxc-001"
    network_interface_name = "nic-utvt-integradora-pe-db-dev-mxc-001"
  }
}

storage_account = {
  name = "stutvtintdevmxc004"

  private_endpoint = {
    name                   = "pep-utvt-integradora-blob-dev-mxc-001"
    network_interface_name = "nic-utvt-integradora-pe-blob-dev-mxc-001"
  }
}
