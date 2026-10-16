data "azurerm_application_insights" "this" {
  count = var.application_insights_name == null ? 0 : 1

  name                = var.application_insights_name
  resource_group_name = local.resource_group_name
}

locals {
  # Instrumentación automática de Application Insights para Node.js en Linux.
  app_insights_settings = var.application_insights_name == null ? {} : {
    APPLICATIONINSIGHTS_CONNECTION_STRING      = one(data.azurerm_application_insights.this[*].connection_string)
    ApplicationInsightsAgent_EXTENSION_VERSION = "~3"
    XDT_MicrosoftApplicationInsights_Mode      = "recommended"
  }

  # Endpoints privados de los servicios de datos (flujos 2 y 3). No hay
  # credenciales: la aplicación obtiene tokens con su identidad administrada y
  # su rol de PostgreSQL lleva el nombre de la Web App.
  data_service_settings = {
    POSTGRES_HOST         = local.data.postgresql_fqdn
    POSTGRES_PORT         = "5432"
    POSTGRES_USER         = var.app_service.web_app_name
    POSTGRES_SSLMODE      = "require"
    STORAGE_BLOB_ENDPOINT = local.data.storage_primary_blob_endpoint
  }
}

resource "azurerm_service_plan" "this" {
  name                = var.app_service.plan_name
  resource_group_name = local.resource_group_name
  location            = local.location
  os_type             = "Linux"
  sku_name            = var.app_service.sku_name
  worker_count        = var.app_service.worker_count
  tags                = local.tags
}

resource "azurerm_linux_web_app" "this" {
  name                = var.app_service.web_app_name
  resource_group_name = local.resource_group_name
  location            = local.location
  service_plan_id     = azurerm_service_plan.this.id

  # Flujo 1: los usuarios acceden por Internet únicamente con HTTPS.
  https_only                    = true
  public_network_access_enabled = true
  client_affinity_enabled       = false

  # Integración regional: el tráfico saliente usa snet-app y sus NSG.
  virtual_network_subnet_id = local.network.subnet_ids["app"]

  # Sin credenciales de publicación básicas (FTP / Web Deploy).
  ftp_publish_basic_authentication_enabled       = false
  webdeploy_publish_basic_authentication_enabled = false

  identity {
    type = "SystemAssigned"
  }

  site_config {
    always_on               = var.app_service.always_on
    ftps_state              = "Disabled"
    http2_enabled           = true
    minimum_tls_version     = "1.2"
    scm_minimum_tls_version = "1.2"
    vnet_route_all_enabled  = true

    application_stack {
      node_version = var.app_service.node_version
    }
  }

  app_settings = merge(local.app_insights_settings, local.data_service_settings)

  tags = local.tags
}
