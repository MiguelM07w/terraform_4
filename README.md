# Terraform · Arquitectura de referencia Azure for Students

Infraestructura como código (IaC) en Terraform de la arquitectura de referencia del proyecto
**integradora** de la UTVT, diseñada con los principios de Azure Landing Zone y del
Well-Architected Framework y desplegada en la suscripción *Azure for Students*
(región **México Central**).

![Arquitectura de referencia](docs/img/arquitectura-referencia.png)

## Componentes

| Capa       | Recurso                               | Detalle                                                    |
|------------|---------------------------------------|------------------------------------------------------------|
| Red        | Virtual Network `10.0.0.0/16`         | 5 subredes, un NSG por subred                               |
| Red        | Private DNS Zones                     | `privatelink.postgres.database.azure.com`, `privatelink.blob.core.windows.net` |
| Datos      | PostgreSQL Flexible Server            | Burstable B1ms, acceso público deshabilitado, Private Endpoint |
| Datos      | Storage Account (Blob)                | Standard LRS, acceso público deshabilitado, Private Endpoint |
| Cómputo    | App Service Linux B1                  | VNet Integration, identidad administrada                   |
| Cómputo    | VM Linux (worker)                     | Sin IP pública, identidad administrada                     |
| Acceso     | Azure Bastion                         | Administración por SSH privado                             |
| Identidad  | Microsoft Entra ID                    | Identidades administradas asignadas por el sistema y RBAC   |

### Flujos de tráfico

| # | Origen      | Destino                     | Protocolo                    |
|---|-------------|-----------------------------|------------------------------|
| 1 | Usuario     | App Service                 | HTTPS 443                    |
| 2 | App Service | PostgreSQL (Private Endpoint) | TLS 5432 con token de la identidad administrada |
| 3 | App Service | Blob (Private Endpoint)     | HTTPS 443 con RBAC           |
| 4 | VM worker   | PostgreSQL (Private Endpoint) | TLS 5432 (consulta de trabajos) |
| 5 | VM worker   | Blob (Private Endpoint)     | HTTPS 443 con RBAC           |
| — | Administrador | VM worker vía Bastion      | Portal TLS 443 → SSH 22 privado |

## Estructura del repositorio

```
.
├── docs/                 # Diagrama, nomenclatura y decisiones de arquitectura
├── modules/              # Módulos reutilizables
└── projects/             # Proyectos raíz, uno por capa, cada uno con su propio estado
    ├── 00-bootstrap/     # Backend remoto del estado de Terraform
    ├── 01-network/       # Grupo de recursos, VNet, subredes, NSG, DNS privado
    ├── 02-data/          # PostgreSQL, Storage Account, Private Endpoints
    └── 03-compute/       # App Service, VM worker, Bastion, RBAC
```

## Documentación

- [Nomenclatura de recursos](docs/nomenclatura.md)
- [Registro de decisiones de arquitectura](docs/decisiones.md)

## Requisitos

| Herramienta  | Versión  |
|--------------|----------|
| Terraform    | ≥ 1.11   |
| Azure CLI    | ≥ 2.60   |
| Proveedor `hashicorp/azurerm` | ~> 5.10 |

La autenticación se realiza con Azure CLI (`az login`). El ID de la suscripción se proporciona
mediante la variable de entorno `ARM_SUBSCRIPTION_ID` y no se versiona.

## Seguridad

- El estado de Terraform se guarda en un backend remoto con autenticación de Entra ID; ningún
  archivo `*.tfstate` se versiona.
- Los archivos `.tfvars` versionados contienen únicamente configuración no sensible. Los secretos
  se proporcionan con variables de entorno `TF_VAR_*`.
- Las llaves SSH, los planes binarios y las salidas con IDs de suscripción están excluidos
  mediante `.gitignore`.
