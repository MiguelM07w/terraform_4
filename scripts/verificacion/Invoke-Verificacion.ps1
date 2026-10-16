<#
.SYNOPSIS
    Verifica de extremo a extremo los flujos de la arquitectura desplegada.

.DESCRIPTION
    Ejecuta las pruebas desde la VM worker con `az vm run-command` (sin SSH ni IP pública):
      1. DNS privado, bloqueo de salida a Internet y flujo 5 (Blob con token de identidad administrada).
      2. Flujo 4 (PostgreSQL con token de identidad administrada por TLS). Con -CrearRolesPostgres,
         antes crea los roles de Entra ID de la Web App y de la VM usando un token del
         administrador limitado a PostgreSQL.
      3. Reglas efectivas de los NSG con IP flow verify de Network Watcher.
    No contiene ni almacena secretos: los tokens se obtienen en tiempo de ejecución.

.EXAMPLE
    ./Invoke-Verificacion.ps1 -CrearRolesPostgres | Tee-Object evidencias/verificacion.txt
#>
[CmdletBinding()]
param(
    [string] $ResourceGroup  = 'rg-utvt-integradora-dev-mxc-001',
    [string] $VmName         = 'vm-utvt-integradora-dev-mxc-001',
    [string] $StorageAccount = 'stutvtintdevmxc004',
    [string] $PostgresServer = 'psql-utvt-integradora-dev-mxc-001-v1',
    [string] $WebAppName     = 'app-utvt-integradora-web-dev-mxc-001-v1',
    [switch] $CrearRolesPostgres,
    [switch] $OmitirPostgres
)

$ErrorActionPreference = 'Stop'

# Azure CLI escribe en la codificación de la consola; con cp1252 descarta los
# acentos de la salida de la VM y emite advertencias por stderr.
[Console]::OutputEncoding = [Text.Encoding]::UTF8
$env:PYTHONIOENCODING = 'utf-8'

$blobHost = "$StorageAccount.blob.core.windows.net"
$pgHost   = "$PostgresServer.postgres.database.azure.com"

function Invoke-VmScript {
    param([string] $Path, [string[]] $Parameters)

    $azArgs = @('vm', 'run-command', 'invoke', '-g', $ResourceGroup, '-n', $VmName,
                '--command-id', 'RunShellScript', '--scripts', "@$Path",
                '--query', 'value[0].message', '-o', 'tsv', '--only-show-errors')
    if ($Parameters) { $azArgs += @('--parameters') + $Parameters }

    # En Windows PowerShell 5.1, la salida de error de un ejecutable nativo se
    # convierte en excepción si se redirige; el resultado se evalúa por código.
    $ErrorActionPreference = 'Continue'
    & az @azArgs
    if ($LASTEXITCODE -ne 0) { throw "Falló la ejecución de $Path en la VM." }
}

function Test-IpFlow {
    param([string] $Direction, [string] $Local, [string] $Remote, [string] $Description)

    $result = az network watcher test-ip-flow -g $ResourceGroup --vm $VmName --direction $Direction `
        --protocol TCP --local $Local --remote $Remote --query "[access, ruleName]" -o tsv --only-show-errors
    $access, $rule = $result -split "`t"
    '{0,-9} {1,-17} {2,-22} {3,-6} {4,-45} {5}' -f $Direction, $Local, $Remote, $access, ($rule -replace '^securityRules/', ''), $Description
}

Write-Host "`n### 1. DNS privado, salida a Internet y flujo 5 (Blob)" -ForegroundColor Cyan
Invoke-VmScript -Path (Join-Path $PSScriptRoot 'verificar-blob.sh') -Parameters @($blobHost, $pgHost)

if (-not $OmitirPostgres) {
    Write-Host "`n### 2. Flujo 4 (PostgreSQL con identidad administrada)" -ForegroundColor Cyan
    $state = az postgres flexible-server show -g $ResourceGroup -n $PostgresServer --query state -o tsv
    if ($state -ne 'Ready') {
        Write-Warning "PostgreSQL está en estado '$state'. Inícielo con: az postgres flexible-server start -g $ResourceGroup -n $PostgresServer"
    }
    else {
        # La plantilla recibe el cliente pgcheck.py embebido en base64 (la VM no tiene Internet).
        $pgcheck  = [Convert]::ToBase64String([IO.File]::ReadAllBytes((Join-Path $PSScriptRoot 'pgcheck.py')))
        $template = [IO.File]::ReadAllText((Join-Path $PSScriptRoot 'verificar-postgres.sh'))
        $payload  = Join-Path ([IO.Path]::GetTempPath()) "verificar-postgres-$([guid]::NewGuid()).sh"
        [IO.File]::WriteAllText($payload, $template.Replace('__PGCHECK_B64__', $pgcheck).Replace("`r`n", "`n"),
                                (New-Object Text.UTF8Encoding $false))
        try {
            if ($CrearRolesPostgres) {
                $adminToken = az account get-access-token --resource-type oss-rdbms --query accessToken -o tsv
                $adminUpn   = az ad signed-in-user show --query userPrincipalName -o tsv
                Invoke-VmScript -Path $payload -Parameters @($adminToken, $adminUpn, $pgHost, $WebAppName, $VmName, 'crear-roles')
            }
            else {
                Invoke-VmScript -Path $payload -Parameters @('-', '-', $pgHost, $WebAppName, $VmName, 'solo-verificar')
            }
        }
        finally {
            Remove-Item $payload -ErrorAction SilentlyContinue
        }
    }
}

Write-Host "`n### 3. Reglas efectivas de los NSG (IP flow verify)" -ForegroundColor Cyan
'{0,-9} {1,-17} {2,-22} {3,-6} {4,-45} {5}' -f 'Dirección', 'Local', 'Remoto', 'Acceso', 'Regla', 'Caso'
Test-IpFlow Inbound  '10.0.3.4:22'    '10.0.5.10:50000'    'SSH desde AzureBastionSubnet'
Test-IpFlow Inbound  '10.0.3.4:22'    '10.0.1.10:50000'    'SSH desde snet-app'
Test-IpFlow Inbound  '10.0.3.4:22'    '203.0.113.10:50000' 'SSH desde Internet'
Test-IpFlow Outbound '10.0.3.4:50000' '10.0.2.4:5432'      'Flujo 4: VM -> PostgreSQL'
Test-IpFlow Outbound '10.0.3.4:50000' '10.0.4.4:443'       'Flujo 5: VM -> Blob'
Test-IpFlow Outbound '10.0.3.4:50000' '10.0.1.10:443'      'Movimiento lateral hacia snet-app'
Test-IpFlow Outbound '10.0.3.4:50000' '10.0.2.4:22'        'Puerto no permitido hacia snet-db'
