#!/bin/bash
# Se ejecuta dentro de la VM worker mediante `az vm run-command invoke`.
# Verifica la resolución DNS privada, el bloqueo de salida a Internet y el
# flujo 5 (VM -> Blob por Private Endpoint con token de identidad administrada).
#
# Uso: verificar-blob.sh <host-blob> <host-postgres>
# Los mensajes se imprimen en ASCII: run-command no conserva UTF-8 en la salida.
set -u
BLOB_HOST="$1"
PG_HOST="$2"

echo "== Identidad del host"
hostname
ip -4 -o addr show scope global | awk '{print $2, $4}'

echo "== Resolucion DNS privada (Private Link)"
getent hosts "$BLOB_HOST"
getent hosts "$PG_HOST"

echo "== Salida a Internet (esperado: bloqueada, subred privada sin NAT)"
if curl -s -m 5 -o /dev/null https://www.microsoft.com; then
  echo "Internet: ACCESIBLE"
else
  echo "Internet: BLOQUEADO"
fi

echo "== Flujo 5: token de la identidad administrada para Storage"
TOKEN=$(curl -s -H "Metadata: true" \
  "http://169.254.169.254/metadata/identity/oauth2/token?api-version=2018-02-01&resource=https://storage.azure.com/" |
  python3 -c 'import sys, json; print(json.load(sys.stdin)["access_token"])')
echo "Token obtenido: ${#TOKEN} caracteres"

echo "== Flujo 5: listado de contenedores por el Private Endpoint (RBAC)"
curl -s -o /tmp/blob-list.xml -w "HTTP %{http_code} desde %{remote_ip}\n" \
  -H "Authorization: Bearer $TOKEN" -H "x-ms-version: 2023-11-03" \
  "https://$BLOB_HOST/?comp=list"
head -c 300 /tmp/blob-list.xml
echo
rm -f /tmp/blob-list.xml
