#!/bin/sh
# ---------------------------------------------------------------------------
# Entrypoint de DESARROLLO.
#
# Al arrancar el contenedor:
#   1. Regenera el cliente del ORM (el código se monta por bind-mount, así que
#      el cliente no viene en la imagen y el esquema puede cambiar en caliente).
#   2. Aplica migraciones y ejecuta el seed (migrate-and-seed.sh).
#   3. Arranca el proceso principal (el `command` del contenedor, p. ej. dev).
# ---------------------------------------------------------------------------
set -e

SCRIPT_DIR="$(dirname "$0")"

echo "▶ [orm] Generando cliente (generate)…"
pnpm prisma generate

sh "$SCRIPT_DIR/migrate-and-seed.sh"

echo "▶ Iniciando: $*"
exec "$@"
