# 02-data · Servicios de datos PaaS

Gestiona Azure Database for PostgreSQL Flexible Server, la cuenta de almacenamiento (Blob) y sus
Private Endpoints. Ningún servicio tiene acceso público: solo se alcanzan desde la VNet.

## Recursos

| Recurso                          | Nombre                                      | Configuración relevante |
|----------------------------------|---------------------------------------------|-------------------------|
| PostgreSQL Flexible Server       | `psql-utvt-integradora-dev-mxc-001-v1`      | v18, Burstable B1ms, 32 GiB P4, zona 1, respaldos de 7 días, acceso público deshabilitado, **solo Entra ID**, `prevent_destroy` |
| Administrador de Entra ID        | Usuario que ejecuta Terraform               | Resuelto con `azuread_user`; configurable con `postgresql_entra_administrator` |
| Private Endpoint - PostgreSQL    | `pep-utvt-integradora-db-dev-mxc-001`       | `snet-db`, NIC `nic-utvt-integradora-pe-db-dev-mxc-001`, IP `10.0.2.4` |
| Storage Account                  | `stutvtintdevmxc004`                        | StorageV2 Standard LRS, Hot, TLS 1.2, **sin llaves compartidas** (solo Entra ID + RBAC), versionado y soft delete de 7 días, `prevent_destroy` |
| Private Endpoint - Blob          | `pep-utvt-integradora-blob-dev-mxc-001`     | `snet-pe`, NIC `nic-utvt-integradora-pe-blob-dev-mxc-001`, IP `10.0.4.4` |

Cada Private Endpoint registra su IP en la zona `privatelink.*` correspondiente (capa `01-network`)
mediante un `private_dns_zone_group`, de modo que los FQDN públicos resuelven a la IP privada
dentro de la VNet.

## Autenticación sin secretos

- **PostgreSQL:** la autenticación por contraseña está deshabilitada. El administrador entra con su
  cuenta de Entra ID y la App Service y la VM con tokens de sus identidades administradas.
  Si un entorno requiere contraseña, se habilita con `postgresql.password_auth_enabled = true` y
  se proporciona como variable **efímera** de **solo escritura** (`administrator_password_wo`),
  que nunca se guarda en el estado:

  ```powershell
  $env:TF_VAR_postgresql_administrator_password = "<contraseña>"
  terraform apply -var-file="env/dev.tfvars" -var="postgresql_administrator_password_version=1"
  ```

  Una precondición detiene el `plan` si se habilita la contraseña sin indicar su versión.
- **Storage:** `shared_access_key_enabled = false` obliga a usar Entra ID; el acceso se concede con
  roles RBAC sobre la cuenta (capa `03-compute`).

## Uso

```powershell
$env:ARM_SUBSCRIPTION_ID = az account show --query id -o tsv
Set-Location projects/02-data

terraform init -backend-config="env/dev.backend.hcl"
terraform plan -var-file="env/dev.tfvars" -out="tfplan"
terraform apply "tfplan"
```

Requiere que `01-network` esté aplicado: lee sus salidas desde `dev/01-network.tfstate`. Azure no
permite modificar un servidor PostgreSQL detenido, así que antes de aplicar cambios hay que
iniciarlo con `az postgres flexible-server start`.
