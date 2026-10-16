# Adopción de los recursos de cómputo creados previamente desde el portal (ADR-001).
# La VM Windows original no se importa: se sustituye por la VM Linux del
# diagrama (ADR-007). Una vez importados en el estado, estos bloques se retiran.

locals {
  rg_id = "/subscriptions/${data.azurerm_client_config.current.subscription_id}/resourceGroups/${local.resource_group_name}"
}

import {
  to = azurerm_service_plan.this
  id = "${local.rg_id}/providers/Microsoft.Web/serverFarms/${var.app_service.plan_name}"
}

import {
  to = azurerm_linux_web_app.this
  id = "${local.rg_id}/providers/Microsoft.Web/sites/${var.app_service.web_app_name}"
}

import {
  to = azurerm_bastion_host.this
  id = "${local.rg_id}/providers/Microsoft.Network/bastionHosts/${var.bastion.name}"
}
