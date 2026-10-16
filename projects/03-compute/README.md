# 03-compute · Cómputo y acceso administrativo

Gestiona la aplicación web, el acceso administrativo por Azure Bastion, la VM Linux worker y las
asignaciones RBAC de sus identidades administradas.

## Recursos

| Recurso                     | Nombre                                        | Configuración relevante |
|-----------------------------|-----------------------------------------------|-------------------------|
| Plan de App Service         | `asp-utvt-integradora-dev-mxc-0001`           | Linux B1, 1 instancia |
| Web App                     | `app-utvt-integradora-web-dev-mxc-001-v1`     | Node 24 LTS, solo HTTPS, TLS 1.2, HTTP/2, FTP y credenciales básicas deshabilitadas, VNet Integration en `snet-app` con `vnet_route_all_enabled`, identidad administrada asignada por el sistema |
| Azure Bastion               | `vnet-utvt-integradora-dev-mxc-001-bastion`   | SKU Developer asociado a la VNet (ADR-005) |

### Configuración de la Web App

Los *app settings* solo contienen endpoints, nunca credenciales:

| Ajuste                                  | Valor                                                    |
|-----------------------------------------|----------------------------------------------------------|
| `POSTGRES_HOST`                         | FQDN del servidor; dentro de la VNet resuelve a `10.0.2.4` |
| `POSTGRES_PORT` / `POSTGRES_SSLMODE`    | `5432` / `require`                                       |
| `POSTGRES_USER`                         | Nombre de la Web App (rol de Entra ID de su identidad)   |
| `STORAGE_BLOB_ENDPOINT`                 | Endpoint de Blob; dentro de la VNet resuelve a `10.0.4.4` |
| `APPLICATIONINSIGHTS_CONNECTION_STRING` | Leída del recurso `appi-utvt-integradora-dev-mxc-001` existente |

La aplicación obtiene tokens de Entra ID con su identidad administrada (por ejemplo, con
`DefaultAzureCredential` del SDK de Azure) para PostgreSQL y Blob.

## Uso

```powershell
$env:ARM_SUBSCRIPTION_ID = az account show --query id -o tsv
Set-Location projects/03-compute

terraform init -backend-config="env/dev.backend.hcl"
terraform plan -var-file="env/dev.tfvars" -out="tfplan"
terraform apply "tfplan"
```

Requiere que `01-network` y `02-data` estén aplicados: lee sus salidas desde
`dev/01-network.tfstate` y `dev/02-data.tfstate`.
