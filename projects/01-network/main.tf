locals {
  tags = merge(var.tags, {
    iac_layer = "01-network"
  })
}

# Grupo de recursos compartido por las capas de red, datos y cómputo.
resource "azurerm_resource_group" "this" {
  name     = var.resource_group_name
  location = var.resource_group_location
  tags     = local.tags

  lifecycle {
    prevent_destroy = true
  }
}

module "vnet" {
  source = "../../modules/virtual-network"

  name                = var.vnet_name
  location            = var.location
  resource_group_name = azurerm_resource_group.this.name
  address_space       = var.vnet_address_space
  subnets             = var.subnets
  tags                = local.tags
}

module "private_dns_zone" {
  source   = "../../modules/private-dns-zone"
  for_each = var.private_dns_zones

  name                = each.value.name
  resource_group_name = azurerm_resource_group.this.name
  tags                = local.tags

  virtual_network_links = {
    workload = {
      name               = each.value.vnet_link_name
      virtual_network_id = module.vnet.id
    }
  }
}
