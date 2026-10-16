#!/bin/bash
# Plantilla que se ejecuta dentro de la VM worker mediante `az vm run-command invoke`.
# Invoke-Verificacion.ps1 sustituye __PGCHECK_B64__ por pgcheck.py en base64,
# porque la VM no tiene salida a Internet para instalar psql.
#
# Uso: verificar-postgres.sh <token-admin|-> <upn-admin|-> <host> <rol-app> <rol-vm> <crear-roles|solo-verificar>
#   El token del administrador (audiencia PostgreSQL, vigencia ~1 h) solo se
#   requiere en modo crear-roles; se recibe como parámetro y nunca se escribe en disco.
set -u
ADMIN_TOKEN="$1"
ADMIN_UPN="$2"
PG_HOST="$3"
APP_ROLE="$4"
VM_ROLE="$5"
MODE="$6"

WORK=$(mktemp -d)
trap 'rm -rf "$WORK" "$0"' EXIT
echo "__PGCHECK_B64__" | base64 -d > "$WORK/pgcheck.py"

echo "== Resolucion DNS"
getent hosts "$PG_HOST"

if [ "$MODE" = "crear-roles" ]; then
  echo "== Administrador de Entra ID: roles para las identidades administradas (idempotente)"
  python3 "$WORK/pgcheck.py" "$PG_HOST" "$ADMIN_UPN" "$ADMIN_TOKEN" "
DO \$\$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM pg_roles WHERE rolname = '$APP_ROLE') THEN
    PERFORM pgaadauth_create_principal('$APP_ROLE', false, false);
  END IF;
  IF NOT EXISTS (SELECT 1 FROM pg_roles WHERE rolname = '$VM_ROLE') THEN
    PERFORM pgaadauth_create_principal('$VM_ROLE', false, false);
  END IF;
END \$\$;
SELECT rolname AS rol, rolcanlogin AS puede_iniciar_sesion
FROM pg_roles WHERE rolname IN ('$APP_ROLE', '$VM_ROLE') ORDER BY 1;"
fi

echo "== Flujo 4: inicio de sesion de la VM con el token de su identidad administrada"
MI_TOKEN=$(curl -s -H "Metadata: true" \
  "http://169.254.169.254/metadata/identity/oauth2/token?api-version=2018-02-01&resource=https://ossrdbms-aad.database.windows.net" |
  python3 -c 'import sys, json; print(json.load(sys.stdin)["access_token"])')
python3 "$WORK/pgcheck.py" "$PG_HOST" "$VM_ROLE" "$MI_TOKEN" \
  "SELECT current_user AS usuario, s.version AS tls, s.cipher AS cifrado,
          split_part(version(), ' on ', 1) AS servidor
   FROM pg_stat_ssl s WHERE s.pid = pg_backend_pid();"
