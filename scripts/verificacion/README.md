# Verificación de los flujos de la arquitectura

Scripts que comprueban, desde dentro de la VNet, que la infraestructura desplegada cumple los
flujos del diagrama. Se ejecutan en la VM worker con `az vm run-command`, sin SSH ni IP pública.

| Archivo                   | Propósito |
|---------------------------|-----------|
| `Invoke-Verificacion.ps1` | Orquesta todas las pruebas desde la estación del administrador |
| `verificar-blob.sh`       | DNS privado, bloqueo de salida a Internet y flujo 5 (Blob con token de identidad administrada) |
| `verificar-postgres.sh`   | Plantilla del flujo 4 (PostgreSQL con token de identidad administrada) y creación idempotente de roles |
| `pgcheck.py`              | Cliente mínimo del protocolo PostgreSQL v3 con TLS, basado solo en la biblioteca estándar, porque la VM no tiene Internet para instalar `psql` |

## Ejecución

```powershell
az login
# PostgreSQL debe estar en estado Ready para la prueba del flujo 4
az postgres flexible-server start -g rg-utvt-integradora-dev-mxc-001 -n psql-utvt-integradora-dev-mxc-001-v1

# Primera vez: crea los roles de Entra ID de la Web App y de la VM
./scripts/verificacion/Invoke-Verificacion.ps1 -CrearRolesPostgres

# Ejecuciones posteriores (sin token del administrador)
./scripts/verificacion/Invoke-Verificacion.ps1
```

## Resultados esperados

| Prueba                                  | Resultado esperado |
|-----------------------------------------|--------------------|
| DNS de Blob y PostgreSQL                | `10.0.4.4` y `10.0.2.4` (zonas `privatelink.*`) |
| Salida a Internet desde la VM           | `BLOQUEADO` |
| Flujo 5 · listado de contenedores       | `HTTP 200 desde 10.0.4.4` |
| Flujo 4 · sesión en PostgreSQL          | `usuario=vm-utvt-integradora-dev-mxc-001`, `tls=TLSv1.3` |
| IP flow verify (flujos 4 y 5, SSH desde AzureBastionSubnet) | `Allow` |
| IP flow verify (SSH desde snet-app e Internet, movimiento lateral) | `Deny` |

## Seguridad

- Ningún archivo contiene secretos. Los tokens se obtienen al ejecutar: los de las identidades
  administradas, del servicio IMDS de la VM; el del administrador, de `az account get-access-token`
  con audiencia exclusiva de PostgreSQL y vigencia de alrededor de una hora.
- El token del administrador solo se envía con `-CrearRolesPostgres`, como parámetro del
  run-command, y nunca se escribe en los scripts. Al terminar, el script elimina de la VM el
  cliente y la plantilla.
