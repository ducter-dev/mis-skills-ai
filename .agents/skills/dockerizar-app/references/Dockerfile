# syntax=docker/dockerfile:1.7

##############################################################################
# Dockerfile multi-stage para una app SSR (Node/Nitro) + ORM + PostgreSQL.
#
# Referencia extraída de un proyecto Nuxt 4 + Prisma 7, pero la ESTRUCTURA es
# reutilizable para cualquier app Node full-stack (Next, Remix, Nest, etc.).
# Adapta los puntos marcados con  <<ADAPTAR>>.
#
# Etapas:
#   base       -> Node + gestor de paquetes + libs del sistema
#   deps       -> node_modules completos (dev + prod) para construir
#   dev        -> servidor de desarrollo con hot-reload
#   build      -> genera cliente del ORM y compila la app (salida autocontenida)
#   production -> imagen mínima que ejecuta solo el servidor compilado
#   nginx      -> sirve estáticos y hace proxy inverso al servidor de la app
#
# Regla de oro del multi-stage: instala/compila en etapas gordas y copia SOLO
# el artefacto final a la imagen de runtime. La imagen de producción no debe
# contener el código fuente, ni devDependencies, ni el gestor de paquetes.
##############################################################################

# --- base -------------------------------------------------------------------
# Alpine para una imagen pequeña. Fija la versión mayor de Node de tu proyecto.
FROM node:24.11-alpine AS base
# <<ADAPTAR>> libs del sistema que necesite tu ORM/driver.
# openssl: requerido por algunas rutas de Prisma. libc6-compat: compat. glibc.
RUN apk add --no-cache openssl libc6-compat
# <<ADAPTAR>> gestor de paquetes. Aquí pnpm vía corepack, fijado a una versión.
RUN corepack enable && corepack prepare pnpm@10.12.3 --activate
ENV PNPM_HOME=/pnpm
ENV PATH="$PNPM_HOME:$PATH"
WORKDIR /app


# --- deps -------------------------------------------------------------------
# Instala TODAS las dependencias (incluye dev) para poder construir.
# --ignore-scripts: los postinstall (p.ej. "nuxt prepare") necesitan el código
# fuente, que aún no está copiado; se ejecutan en la etapa build.
FROM base AS deps
COPY package.json pnpm-lock.yaml pnpm-workspace.yaml ./
RUN --mount=type=cache,id=pnpm-store,target=/pnpm/store \
    pnpm install --frozen-lockfile --ignore-scripts


# --- dev --------------------------------------------------------------------
# Servidor de desarrollo con hot-reload. El código se monta por bind-mount
# desde docker-compose, así que aquí solo dejamos las dependencias listas.
FROM base AS dev
ENV NODE_ENV=development
# <<ADAPTAR>> el servidor debe escuchar en 0.0.0.0 dentro del contenedor.
ENV NUXT_HOST=0.0.0.0
ENV NUXT_PORT=3000
COPY --from=deps /app/node_modules ./node_modules
COPY . .
EXPOSE 3000
CMD ["pnpm", "dev", "--host"]


# --- build ------------------------------------------------------------------
# Genera el cliente del ORM y compila la app. La salida (.output en Nitro) es
# autocontenida: incluye las dependencias de runtime que necesita.
FROM base AS build
ENV NODE_ENV=production
COPY --from=deps /app/node_modules ./node_modules
COPY . .
# <<ADAPTAR>> Muchos ORMs (Prisma) exigen resolver DATABASE_URL al cargar su
# config, aunque `generate`/`build` NO se conecten a la BD. Un valor dummy como
# ARG basta y NO persiste en la imagen final.
ARG DATABASE_URL="postgresql://build:build@localhost:5432/build?schema=public"
RUN pnpm prisma generate
RUN pnpm build


# --- production -------------------------------------------------------------
# Imagen mínima de runtime: solo Node + la salida autocontenida del build.
FROM node:24.11-alpine AS production
RUN apk add --no-cache openssl libc6-compat
WORKDIR /app
ENV NODE_ENV=production
ENV HOST=0.0.0.0
ENV PORT=3000
# Usuario no-root para reducir la superficie de ataque.
RUN addgroup -g 1001 -S nodejs && adduser -S appuser -u 1001
# <<ADAPTAR>> copia SOLO el artefacto de build. Aquí .output de Nitro.
COPY --from=build --chown=appuser:nodejs /app/.output ./.output
USER appuser
EXPOSE 3000
# Healthcheck sin curl/wget: usa el fetch nativo de Node.
# <<ADAPTAR>> apunta a un endpoint barato de tu app (/, /healthz…).
HEALTHCHECK --interval=30s --timeout=5s --start-period=20s --retries=3 \
  CMD node -e "fetch('http://127.0.0.1:3000/').then(r=>process.exit(r.ok?0:1)).catch(()=>process.exit(1))"
CMD ["node", ".output/server/index.mjs"]


# --- nginx ------------------------------------------------------------------
# Sirve los estáticos compilados desde disco y hace proxy inverso de las
# peticiones dinámicas (SSR + API) al servidor de la app (servicio "app").
FROM nginx:1.27-alpine AS nginx
# <<ADAPTAR>> ruta de los estáticos compilados dentro del artefacto.
COPY --from=build /app/.output/public /usr/share/nginx/html
COPY docker/nginx/default.conf /etc/nginx/conf.d/default.conf
EXPOSE 80
HEALTHCHECK --interval=30s --timeout=5s --retries=3 \
  CMD wget -qO- http://127.0.0.1/healthz || exit 1
