# Nomenclatura de recursos

## Convención

Los nombres siguen la guía de nomenclatura del Cloud Adoption Framework (CAF) de Microsoft:

```
<abreviatura>-<organización>-<proyecto>-<rol>-<entorno>-<región>-<instancia>
```

| Segmento     | Valor         | Significado                            |
|--------------|---------------|----------------------------------------|
| organización | `utvt`        | Universidad Tecnológica del Valle de Toluca |
| proyecto     | `integradora` | Proyecto integrador                    |
| entorno      | `dev`         | Desarrollo                             |
| región       | `mxc`         | Azure México Central (`mexicocentral`) |
| instancia    | `001`         | Consecutivo                            |

Las cuentas de almacenamiento no admiten guiones y tienen un máximo de 24 caracteres,
por lo que usan una forma abreviada (`stutvtintdevmxc004`).

## 1. Recursos definidos en la tabla de diseño

La tabla de diseño es la **fuente de verdad**: cuando un nombre del diagrama no coincide con
la tabla, prevalece la tabla.

| Recurso                                | Nombre (dev)                               | CIDR del diseño |
|----------------------------------------|--------------------------------------------|-----------------|
| Red virtual                            | `vnet-utvt-integradora-dev-mxc-001`        | `10.0.0.0/16`   |
| Integración de App Service             | `snet-utvt-integradora-app-dev-mxc-001`    | `10.0.1.0/24`   |
| Base de datos (reservada)              | `snet-utvt-integradora-db-dev-mxc-001`     | `10.0.2.0/24`   |
| Máquina virtual                        | `snet-utvt-integradora-vm-dev-mxc-001`     | `10.0.3.0/24`   |
| Private Endpoints                      | `snet-utvt-integradora-pe-dev-mxc-001`     | `10.0.4.0/24`   |
| Azure Bastion dedicado                 | `AzureBastionSubnet`                       | `10.0.5.0/24`   |
| Servidor PostgreSQL Flexible Server    | `psql-utvt-integradora-dev-mxc-001-v1`     | N/A             |
| Private Endpoint - PostgreSQL          | `pep-utvt-integradora-db-dev-mxc-001`      | N/A             |
| Interfaz de red del endpoint - PostgreSQL | `nic-utvt-integradora-pe-db-dev-mxc-001` |                 |
| Cuenta de almacenamiento               | `stutvtintdevmxc004`                       |                 |
| Private Endpoint - Blob                | `pep-utvt-integradora-blob-dev-mxc-001`    |                 |
| Interfaz de red del endpoint - Blob    | `nic-utvt-integradora-pe-blob-dev-mxc-001` |                 |
| Subred - Blob                          | `snet-utvt-integradora-pe-dev-mxc-001`     |                 |
| Zona DNS privada - Blob                | `privatelink.blob.core.windows.net`        |                 |

## 2. Recursos existentes que no aparecen en la tabla

Se conserva el nombre con el que ya existen en Azure: en estos recursos el nombre no se puede
cambiar sin destruirlos y volver a crearlos.

| Recurso                     | Nombre                                        |
|-----------------------------|-----------------------------------------------|
| Grupo de recursos           | `rg-utvt-integradora-dev-mxc-001`             |
| Plan de App Service (B1 Linux) | `asp-utvt-integradora-dev-mxc-0001`        |
| Web App                     | `app-utvt-integradora-web-dev-mxc-001-v1`     |
| Azure Bastion (SKU Developer) | `vnet-utvt-integradora-dev-mxc-001-bastion` |
| Zona DNS privada - PostgreSQL | `privatelink.postgres.database.azure.com`   |

## 3. Recursos nuevos creados por Terraform

| Recurso                                  | Nombre                                              |
|------------------------------------------|-----------------------------------------------------|
| NSG - subred de App Service              | `nsg-utvt-integradora-app-dev-mxc-001`              |
| NSG - subred de base de datos            | `nsg-utvt-integradora-db-dev-mxc-001`               |
| NSG - subred de la máquina virtual       | `nsg-utvt-integradora-vm-dev-mxc-001`               |
| NSG - subred de Private Endpoints        | `nsg-utvt-integradora-pe-dev-mxc-001`               |
| NSG - AzureBastionSubnet                 | `nsg-utvt-integradora-bastion-dev-mxc-001`          |
| Vínculo VNet - zona DNS PostgreSQL       | `pdnslink-utvt-integradora-postgres-dev-mxc-001`    |
| Vínculo VNet - zona DNS Blob             | `pdnslink-utvt-integradora-blob-dev-mxc-001`        |
| Máquina virtual Linux (worker)           | `vm-utvt-integradora-dev-mxc-001`                   |
| Interfaz de red de la VM                 | `nic-utvt-integradora-vm-dev-mxc-001`               |
| Disco del sistema operativo de la VM     | `osdisk-utvt-integradora-vm-dev-mxc-001`            |
| Grupo de recursos del estado remoto      | `rg-utvt-tfstate-dev-mxc-001`                       |
| Cuenta de almacenamiento del estado      | `sttfutvtintdevmxc001`                              |
| Contenedor del estado                    | `tfstate`                                           |

## 4. Diferencias entre el diagrama y la tabla

| Diagrama                 | Tabla / implementación                     | Motivo                                  |
|--------------------------|--------------------------------------------|-----------------------------------------|
| `vnet-lz-prod`           | `vnet-utvt-integradora-dev-mxc-001`        | El entorno desplegado es desarrollo     |
| `snet-app`               | `snet-utvt-integradora-app-dev-mxc-001`    | Convención CAF de la tabla              |
| `snet-db`                | `snet-utvt-integradora-db-dev-mxc-001`     | Convención CAF de la tabla              |
| `snet-vm`                | `snet-utvt-integradora-vm-dev-mxc-001`     | Convención CAF de la tabla              |
| `snet-endpoints`         | `snet-utvt-integradora-pe-dev-mxc-001`     | Convención CAF de la tabla              |
| `nsg-app`, `nsg-db`, ... | `nsg-utvt-integradora-<rol>-dev-mxc-001`   | Misma convención para recursos nuevos   |
| `AzureBastionSubnet`     | `AzureBastionSubnet`                       | Nombre obligatorio definido por Azure   |
