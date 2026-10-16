location                = "mexicocentral"
resource_group_name     = "rg-utvt-integradora-dev-mxc-001"
resource_group_location = "eastus"

vnet_name          = "vnet-utvt-integradora-dev-mxc-001"
vnet_address_space = ["10.0.0.0/16"]

# Las subredes son privadas (sin acceso de salida implícito a Internet).
# En las subredes con Private Endpoints se habilitan las políticas de red para
# que los NSG filtren el tráfico hacia los endpoints.
subnets = {
  app = {
    name             = "snet-utvt-integradora-app-dev-mxc-001"
    address_prefixes = ["10.0.1.0/24"]
    delegation = {
      name    = "delegation"
      service = "Microsoft.Web/serverFarms"
      actions = ["Microsoft.Network/virtualNetworks/subnets/action"]
    }
  }
  db = {
    name                              = "snet-utvt-integradora-db-dev-mxc-001"
    address_prefixes                  = ["10.0.2.0/24"]
    private_endpoint_network_policies = "NetworkSecurityGroupEnabled"
  }
  vm = {
    name             = "snet-utvt-integradora-vm-dev-mxc-001"
    address_prefixes = ["10.0.3.0/24"]
  }
  pe = {
    name                              = "snet-utvt-integradora-pe-dev-mxc-001"
    address_prefixes                  = ["10.0.4.0/24"]
    private_endpoint_network_policies = "NetworkSecurityGroupEnabled"
  }
  bastion = {
    name             = "AzureBastionSubnet"
    address_prefixes = ["10.0.5.0/24"]
  }
}

network_security_groups = {
  app     = "nsg-utvt-integradora-app-dev-mxc-001"
  db      = "nsg-utvt-integradora-db-dev-mxc-001"
  vm      = "nsg-utvt-integradora-vm-dev-mxc-001"
  pe      = "nsg-utvt-integradora-pe-dev-mxc-001"
  bastion = "nsg-utvt-integradora-bastion-dev-mxc-001"
}

private_dns_zones = {
  postgres = {
    name           = "privatelink.postgres.database.azure.com"
    vnet_link_name = "pdnslink-utvt-integradora-postgres-dev-mxc-001"
  }
  blob = {
    name           = "privatelink.blob.core.windows.net"
    vnet_link_name = "pdnslink-utvt-integradora-blob-dev-mxc-001"
  }
}

tags = {
  environment = "dev"
  project     = "integradora"
  cost_center = "utvt"
  owner       = "equipo-integradora"
  managed_by  = "terraform"
  repository  = "github.com/MiguelM07w/terraform_4"
}
