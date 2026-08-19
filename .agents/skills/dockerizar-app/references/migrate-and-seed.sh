#!/bin/sh
# ---------------------------------------------------------------------------
# Aplica migraciones del ORM y ejecuta el seed (si existe).
#
# IMPORTANTE: esto corre al ARRANCAR el contenedor, no durante `docker build`.
# En build no hay base de datos disponible, por lo que migraciones/seeders
# nunca deben ejecutarse ahí.
#
# Usado por:
#   - Prod/QA: el servicio one-shot "migrate" (docker-compose.prod|qa.yml)
#   - Desarrollo: el entrypoint docker-entrypoint.sh
# ---------------------------------------------------------------------------
set -e

echo "▶ [orm] Aplicando migraciones pendientes (migrate deploy)…"
pnpm prisma migrate deploy

# El seed es opcional: se ejecuta solo si prisma/seed.ts existe.
# NOTA: haz que tu seed sea IDEMPOTENTE (usa upsert), ya que puede correr en
# cada arranque.
if [ -f prisma/seed.ts ]; then
  echo "▶ [orm] Ejecutando seed (db seed)…"
  pnpm prisma db seed
else
  echo "▶ [orm] No existe prisma/seed.ts; se omite el seed."
fi

echo "▶ [orm] Migraciones y seed completados."
