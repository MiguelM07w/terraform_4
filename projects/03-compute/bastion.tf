# Bastion Developer (ADR-005): sin costo, sin IP pública y sin desplegarse en
# AzureBastionSubnet; se asocia directamente a la VNet.
resource "azurerm_bastion_host" "this" {
  name                = var.bastion.name
  resource_group_name = local.resource_group_name
  location            = local.location
  sku                 = var.bastion.sku
  virtual_network_id  = local.network.vnet_id
  tags                = local.tags
}
