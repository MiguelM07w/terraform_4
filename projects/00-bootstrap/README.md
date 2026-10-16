# 00-bootstrap · Estado remoto de Terraform

Crea el backend `azurerm` donde los demás proyectos guardan su estado:

| Recurso                | Nombre                         | Configuración relevante                                   |
|------------------------|--------------------------------|-----------------------------------------------------------|
| Grupo de recursos      | `rg-utvt-tfstate-dev-mxc-001`  | Separado de la carga de trabajo                            |
| Storage Account        | `sttfutvtintdevmxc001`         | ZRS, TLS 1.2, sin llaves compartidas (solo Entra ID), versionado y soft delete de 30 días, `prevent_destroy` |
| Contenedor             | `tfstate`                      | Privado                                                   |
| Asignación de rol      | Storage Blob Data Contributor  | Para la identidad que ejecuta Terraform                    |

El bloqueo del estado se realiza de forma nativa mediante *blob leases* del backend `azurerm`.

## Primera ejecución (backend local temporal)

El backend no puede guardar su propio estado antes de existir. Por eso la primera ejecución usa
un backend local mediante un archivo *override*, que no se versiona (`*_override.tf`):

```powershell
$env:ARM_SUBSCRIPTION_ID = az account show --query id -o tsv
Set-Location projects/00-bootstrap

'terraform { backend "local" {} }' | Out-File -Encoding utf8 backend_override.tf

terraform init
terraform plan  -var-file="env/dev.tfvars" -out="tfplan"
terraform apply "tfplan"
```

## Migración del estado al backend remoto

La asignación de rol puede tardar unos minutos en propagarse. Después se migra el estado local
al contenedor recién creado:

```powershell
Remove-Item backend_override.tf
terraform init -migrate-state -backend-config="env/dev.backend.hcl"
Remove-Item terraform.tfstate, terraform.tfstate.backup
```

## Ejecuciones posteriores

```powershell
terraform init -backend-config="env/dev.backend.hcl"
terraform plan -var-file="env/dev.tfvars"
```
