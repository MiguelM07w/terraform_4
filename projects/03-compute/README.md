# 03-compute · Cómputo y acceso administrativo

Gestiona la aplicación web, el acceso administrativo por Azure Bastion, la VM Linux worker y las
asignaciones RBAC de sus identidades administradas.

## Recursos

| Recurso                     | Nombre                                        | Configuración relevante |
|-----------------------------|-----------------------------------------------|-------------------------|
| Plan de App Service         | `asp-utvt-integradora-dev-mxc-0001`           | Linux B1, 1 instancia |
| Web App                     | `app-utvt-integradora-web-dev-mxc-001-v1`     | Node 24 LTS, solo HTTPS, TLS 1.2, HTTP/2, FTP y credenciales básicas deshabilitadas, VNet Integration en `snet-app` con `vnet_route_all_enabled`, identidad administrada asignada por el sistema |
| Azure Bastion               | `vnet-utvt-integradora-dev-mxc-001-bastion`   | SKU Developer asociado a la VNet (ADR-005) |
| VM Linux worker             | `vm-utvt-integradora-dev-mxc-001`             | Ubuntu 24.04 LTS, `Standard_B2ats_v2`, zona 1, Trusted Launch, solo llave SSH, sin IP pública, identidad administrada (ADR-007) |
| NIC de la VM                | `nic-utvt-integradora-vm-dev-mxc-001`         | `snet-vm`, IP dinámica (`10.0.3.4`), accelerated networking |
| Disco del SO                | `osdisk-utvt-integradora-vm-dev-mxc-001`      | StandardSSD LRS, 30 GiB |
| Asignaciones RBAC           | Storage Blob Data Contributor                 | Identidades de la Web App y de la VM sobre `stutvtintdevmxc004` |

## Identidades y permisos

| Identidad (asignada por el sistema) | Blob (flujos 3 y 5)                                       | PostgreSQL (flujos 2 y 4) |
|-------------------------------------|-----------------------------------------------------------|---------------------------|
| `app-utvt-integradora-web-dev-mxc-001-v1` | Storage Blob Data Contributor (Terraform, `rbac.tf`) | Rol de Entra ID `app-utvt-integradora-web-dev-mxc-001-v1` |
| `vm-utvt-integradora-dev-mxc-001`         | Storage Blob Data Contributor (Terraform, `rbac.tf`) | Rol de Entra ID `vm-utvt-integradora-dev-mxc-001` |

Los roles de PostgreSQL pertenecen al plano de datos del servidor y no se pueden declarar con el
proveedor `azurerm`. Los crea el administrador de Entra ID una sola vez, desde la VNet:

```sql
SELECT * FROM pgaadauth_create_principal('app-utvt-integradora-web-dev-mxc-001-v1', false, false);
SELECT * FROM pgaadauth_create_principal('vm-utvt-integradora-dev-mxc-001', false, false);
```

Los permisos sobre bases de datos y esquemas concretos (`GRANT ...`) corresponden a la aplicación.

## Acceso administrativo a la VM

1. Generar el par de llaves en la estación del administrador (la llave privada nunca se versiona):

   ```powershell
   ssh-keygen -t rsa -b 4096 -f "$HOME/.ssh/id_rsa_utvt_integradora"
   ```

2. En el portal: **VM → Conectar → Bastion**, con el usuario `azureuser` y el archivo de llave privada
   local. Bastion Developer entra a la VM desde `168.63.129.16`, origen que el NSG de `snet-vm`
   permite en el puerto 22.

La subred de la VM es privada y no tiene NAT Gateway, así que no hay salida a Internet (ADR-007).

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
`dev/01-network.tfstate` y `dev/02-data.tfstate`, y que exista la llave pública indicada en
`vm.ssh_public_key_path`.
