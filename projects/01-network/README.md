# 01-network · Red de la carga de trabajo

Gestiona el grupo de recursos compartido, la red virtual, las subredes, los grupos de seguridad
de red (NSG) y las zonas DNS privadas de Private Link.

## Recursos

| Recurso                     | Nombre                                           | Origen     |
|-----------------------------|--------------------------------------------------|------------|
| Grupo de recursos           | `rg-utvt-integradora-dev-mxc-001`                | Importado  |
| Red virtual `10.0.0.0/16`   | `vnet-utvt-integradora-dev-mxc-001`              | Importado  |
| Subred `10.0.1.0/24`        | `snet-utvt-integradora-app-dev-mxc-001` (delegada a `Microsoft.Web/serverFarms`) | Importado |
| Subred `10.0.2.0/24`        | `snet-utvt-integradora-db-dev-mxc-001`           | Importado  |
| Subred `10.0.3.0/24`        | `snet-utvt-integradora-vm-dev-mxc-001`           | Importado  |
| Subred `10.0.4.0/24`        | `snet-utvt-integradora-pe-dev-mxc-001`           | Importado  |
| Subred `10.0.5.0/24`        | `AzureBastionSubnet`                             | Importado  |
| 5 NSG (uno por subred)      | `nsg-utvt-integradora-<rol>-dev-mxc-001`         | Nuevo      |
| Zona DNS privada            | `privatelink.postgres.database.azure.com`        | Importado  |
| Zona DNS privada            | `privatelink.blob.core.windows.net`              | Importado  |
| Vínculos VNet ↔ zona DNS    | `pdnslink-utvt-integradora-<zona>-dev-mxc-001`   | Reemplazado |

Todas las subredes son **privadas** (`default_outbound_access_enabled = false`). En las subredes
`db` y `pe` se habilitan las políticas de red de Private Endpoints para que los NSG filtren el
tráfico hacia los endpoints.

## Matriz de tráfico permitido

| NSG       | Dirección | Origen                   | Destino        | Puerto | Flujo del diagrama |
|-----------|-----------|--------------------------|----------------|--------|--------------------|
| `app`     | Saliente  | `10.0.1.0/24`            | `10.0.2.0/24`  | 5432   | 2 · App → PostgreSQL |
| `app`     | Saliente  | `10.0.1.0/24`            | `10.0.4.0/24`  | 443    | 3 · App → Blob     |
| `db`      | Entrante  | `10.0.1.0/24`            | `10.0.2.0/24`  | 5432   | 2 · App → PostgreSQL |
| `db`      | Entrante  | `10.0.3.0/24`            | `10.0.2.0/24`  | 5432   | 4 · VM → PostgreSQL |
| `vm`      | Entrante  | `168.63.129.16/32`       | `10.0.3.0/24`  | 22     | Bastion Developer → VM |
| `vm`      | Entrante  | `10.0.5.0/24`            | `10.0.3.0/24`  | 22     | Bastion dedicado → VM |
| `vm`      | Saliente  | `10.0.3.0/24`            | `10.0.2.0/24`  | 5432   | 4 · VM → PostgreSQL |
| `vm`      | Saliente  | `10.0.3.0/24`            | `10.0.4.0/24`  | 443    | 5 · VM → Blob      |
| `pe`      | Entrante  | `10.0.1.0/24`            | `10.0.4.0/24`  | 443    | 3 · App → Blob     |
| `pe`      | Entrante  | `10.0.3.0/24`            | `10.0.4.0/24`  | 443    | 5 · VM → Blob      |
| `bastion` | Ambas     | Reglas obligatorias de Azure Bastion | | 443, 80, 22, 3389, 8080, 5701 | Administración |

Todo el demás tráfico entrante se bloquea (`DenyAllInbound`, prioridad 4096), y el tráfico
saliente de `app` y `vm` hacia otros destinos dentro de la VNet también (`DenyVirtualNetworkOutbound`,
prioridad 4000).

## Uso

```powershell
$env:ARM_SUBSCRIPTION_ID = az account show --query id -o tsv
Set-Location projects/01-network

terraform init -backend-config="env/dev.backend.hcl"
terraform plan -var-file="env/dev.tfvars" -out="tfplan"
terraform apply "tfplan"
```

## Salidas consumidas por otras capas

`resource_group_name`, `location`, `tags`, `vnet_id`, `subnet_ids`, `subnet_address_prefixes`,
`network_security_group_ids` y `private_dns_zone_ids`, mediante `terraform_remote_state` sobre la
llave `dev/01-network.tfstate`.
