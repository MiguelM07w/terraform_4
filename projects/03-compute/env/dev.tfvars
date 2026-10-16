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
