# Reglas de los NSG derivadas de los flujos del diagrama de referencia.
# Cada subred permite exclusivamente el tráfico documentado y bloquea el resto
# del tráfico interno (segmentación de mínimo privilegio).

locals {
  cidr = { for alias, s in var.subnets : alias => s.address_prefixes[0] }

  # Azure Bastion Developer (sin subred dedicada) se conecta a las VM desde la
  # IP virtual de la plataforma de Azure.
  bastion_developer_source = "168.63.129.16/32"

  nsg_rules = {
    # --- snet-app: integración regional de App Service (solo tráfico saliente) ---
    app = {
      AllowPostgresToDbOutbound = {
        description                = "Flujo 2: App Service hacia el Private Endpoint de PostgreSQL"
        priority                   = 100
        direction                  = "Outbound"
        access                     = "Allow"
        protocol                   = "Tcp"
        source_address_prefix      = local.cidr.app
        destination_address_prefix = local.cidr.db
        destination_port_range     = "5432"
      }
      AllowHttpsToPrivateEndpointsOutbound = {
        description                = "Flujo 3: App Service hacia el Private Endpoint de Blob"
        priority                   = 110
        direction                  = "Outbound"
        access                     = "Allow"
        protocol                   = "Tcp"
        source_address_prefix      = local.cidr.app
        destination_address_prefix = local.cidr.pe
        destination_port_range     = "443"
      }
      DenyVirtualNetworkOutbound = {
        description                = "Bloquea cualquier otro destino dentro de la VNet"
        priority                   = 4000
        direction                  = "Outbound"
        access                     = "Deny"
        protocol                   = "*"
        source_address_prefix      = "*"
        destination_address_prefix = "VirtualNetwork"
        destination_port_range     = "*"
      }
    }

    # --- snet-db: Private Endpoint de PostgreSQL ---
    db = {
      AllowPostgresFromAppInbound = {
        description                = "Flujo 2: App Service hacia PostgreSQL"
        priority                   = 100
        direction                  = "Inbound"
        access                     = "Allow"
        protocol                   = "Tcp"
        source_address_prefix      = local.cidr.app
        destination_address_prefix = local.cidr.db
        destination_port_range     = "5432"
      }
      AllowPostgresFromVmInbound = {
        description                = "Flujo 4: VM worker hacia PostgreSQL"
        priority                   = 110
        direction                  = "Inbound"
        access                     = "Allow"
        protocol                   = "Tcp"
        source_address_prefix      = local.cidr.vm
        destination_address_prefix = local.cidr.db
        destination_port_range     = "5432"
      }
      DenyAllInbound = {
        description                = "Bloquea cualquier otro tráfico entrante"
        priority                   = 4096
        direction                  = "Inbound"
        access                     = "Deny"
        protocol                   = "*"
        source_address_prefix      = "*"
        destination_address_prefix = "*"
        destination_port_range     = "*"
      }
    }

    # --- snet-vm: VM Linux worker ---
    vm = {
      AllowSshFromBastionDeveloperInbound = {
        description                = "Administración: SSH desde Azure Bastion Developer"
        priority                   = 100
        direction                  = "Inbound"
        access                     = "Allow"
        protocol                   = "Tcp"
        source_address_prefix      = local.bastion_developer_source
        destination_address_prefix = local.cidr.vm
        destination_port_range     = "22"
      }
      AllowSshFromBastionSubnetInbound = {
        description                = "Administración: SSH desde un Bastion dedicado en AzureBastionSubnet"
        priority                   = 110
        direction                  = "Inbound"
        access                     = "Allow"
        protocol                   = "Tcp"
        source_address_prefix      = local.cidr.bastion
        destination_address_prefix = local.cidr.vm
        destination_port_range     = "22"
      }
      DenyAllInbound = {
        description                = "Bloquea cualquier otro tráfico entrante"
        priority                   = 4096
        direction                  = "Inbound"
        access                     = "Deny"
        protocol                   = "*"
        source_address_prefix      = "*"
        destination_address_prefix = "*"
        destination_port_range     = "*"
      }
      AllowPostgresToDbOutbound = {
        description                = "Flujo 4: VM worker hacia el Private Endpoint de PostgreSQL"
        priority                   = 100
        direction                  = "Outbound"
        access                     = "Allow"
        protocol                   = "Tcp"
        source_address_prefix      = local.cidr.vm
        destination_address_prefix = local.cidr.db
        destination_port_range     = "5432"
      }
      AllowHttpsToPrivateEndpointsOutbound = {
        description                = "Flujo 5: VM worker hacia el Private Endpoint de Blob"
        priority                   = 110
        direction                  = "Outbound"
        access                     = "Allow"
        protocol                   = "Tcp"
        source_address_prefix      = local.cidr.vm
        destination_address_prefix = local.cidr.pe
        destination_port_range     = "443"
      }
      DenyVirtualNetworkOutbound = {
        description                = "Bloquea cualquier otro destino dentro de la VNet"
        priority                   = 4000
        direction                  = "Outbound"
        access                     = "Deny"
        protocol                   = "*"
        source_address_prefix      = "*"
        destination_address_prefix = "VirtualNetwork"
        destination_port_range     = "*"
      }
    }

    # --- snet-pe: Private Endpoint de Blob Storage ---
    pe = {
      AllowHttpsFromAppInbound = {
        description                = "Flujo 3: App Service hacia Blob"
        priority                   = 100
        direction                  = "Inbound"
        access                     = "Allow"
        protocol                   = "Tcp"
        source_address_prefix      = local.cidr.app
        destination_address_prefix = local.cidr.pe
        destination_port_range     = "443"
      }
      AllowHttpsFromVmInbound = {
        description                = "Flujo 5: VM worker hacia Blob"
        priority                   = 110
        direction                  = "Inbound"
        access                     = "Allow"
        protocol                   = "Tcp"
        source_address_prefix      = local.cidr.vm
        destination_address_prefix = local.cidr.pe
        destination_port_range     = "443"
      }
      DenyAllInbound = {
        description                = "Bloquea cualquier otro tráfico entrante"
        priority                   = 4096
        direction                  = "Inbound"
        access                     = "Deny"
        protocol                   = "*"
        source_address_prefix      = "*"
        destination_address_prefix = "*"
        destination_port_range     = "*"
      }
    }

    # --- AzureBastionSubnet: reglas obligatorias de Azure Bastion ---
    # https://learn.microsoft.com/azure/bastion/bastion-nsg
    bastion = {
      AllowHttpsInbound = {
        description                = "Sesiones de los usuarios por HTTPS"
        priority                   = 120
        direction                  = "Inbound"
        access                     = "Allow"
        protocol                   = "Tcp"
        source_address_prefix      = "Internet"
        destination_address_prefix = "*"
        destination_port_range     = "443"
      }
      AllowGatewayManagerInbound = {
        description                = "Plano de control de Azure Bastion"
        priority                   = 130
        direction                  = "Inbound"
        access                     = "Allow"
        protocol                   = "Tcp"
        source_address_prefix      = "GatewayManager"
        destination_address_prefix = "*"
        destination_port_range     = "443"
      }
      AllowAzureLoadBalancerInbound = {
        description                = "Sondeos de estado de Azure Load Balancer"
        priority                   = 140
        direction                  = "Inbound"
        access                     = "Allow"
        protocol                   = "Tcp"
        source_address_prefix      = "AzureLoadBalancer"
        destination_address_prefix = "*"
        destination_port_range     = "443"
      }
      AllowBastionHostCommunicationInbound = {
        description                = "Comunicación interna entre instancias de Bastion"
        priority                   = 150
        direction                  = "Inbound"
        access                     = "Allow"
        protocol                   = "*"
        source_address_prefix      = "VirtualNetwork"
        destination_address_prefix = "VirtualNetwork"
        destination_port_ranges    = ["8080", "5701"]
      }
      AllowSshRdpOutbound = {
        description                = "Sesiones SSH/RDP hacia las VM por IP privada"
        priority                   = 100
        direction                  = "Outbound"
        access                     = "Allow"
        protocol                   = "*"
        source_address_prefix      = "*"
        destination_address_prefix = "VirtualNetwork"
        destination_port_ranges    = ["22", "3389"]
      }
      AllowAzureCloudOutbound = {
        description                = "Registros de diagnóstico y medición"
        priority                   = 110
        direction                  = "Outbound"
        access                     = "Allow"
        protocol                   = "Tcp"
        source_address_prefix      = "*"
        destination_address_prefix = "AzureCloud"
        destination_port_range     = "443"
      }
      AllowBastionCommunicationOutbound = {
        description                = "Comunicación interna entre instancias de Bastion"
        priority                   = 120
        direction                  = "Outbound"
        access                     = "Allow"
        protocol                   = "*"
        source_address_prefix      = "VirtualNetwork"
        destination_address_prefix = "VirtualNetwork"
        destination_port_ranges    = ["8080", "5701"]
      }
      AllowHttpOutbound = {
        description                = "Validación de sesiones y certificados"
        priority                   = 130
        direction                  = "Outbound"
        access                     = "Allow"
        protocol                   = "*"
        source_address_prefix      = "*"
        destination_address_prefix = "Internet"
        destination_port_range     = "80"
      }
    }
  }
}

module "nsg" {
  source   = "../../modules/network-security-group"
  for_each = var.network_security_groups

  name                = each.value
  location            = var.location
  resource_group_name = azurerm_resource_group.this.name
  security_rules      = local.nsg_rules[each.key]
  tags                = local.tags

  subnet_ids = {
    (each.key) = module.vnet.subnet_ids[each.key]
  }
}
