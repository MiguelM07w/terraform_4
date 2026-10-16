remote_state = {
  resource_group_name  = "rg-utvt-tfstate-dev-mxc-001"
  storage_account_name = "sttfutvtintdevmxc001"
  container_name       = "tfstate"
  network_key          = "dev/01-network.tfstate"
  data_key             = "dev/02-data.tfstate"
}

app_service = {
  plan_name    = "asp-utvt-integradora-dev-mxc-0001"
  sku_name     = "B1"
  web_app_name = "app-utvt-integradora-web-dev-mxc-001-v1"
  node_version = "24-lts"
}

application_insights_name = "appi-utvt-integradora-dev-mxc-001"

bastion = {
  name = "vnet-utvt-integradora-dev-mxc-001-bastion"
  sku  = "Developer"
}

# Standard_B2ats_v2 está restringido en la zona 3 de México Central para esta
# suscripción; se ubica en la zona 1, la misma de PostgreSQL.
vm = {
  name                   = "vm-utvt-integradora-dev-mxc-001"
  size                   = "Standard_B2ats_v2"
  zone                   = "1"
  admin_username         = "azureuser"
  ssh_public_key_path    = "~/.ssh/id_rsa_utvt_integradora.pub"
  network_interface_name = "nic-utvt-integradora-vm-dev-mxc-001"
  os_disk_name           = "osdisk-utvt-integradora-vm-dev-mxc-001"

  image = {
    publisher = "Canonical"
    offer     = "ubuntu-24_04-lts"
    sku       = "server"
    version   = "latest"
  }
}
