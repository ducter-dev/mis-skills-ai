---
name: dockerizar-app
description: Dockeriza una app web full-stack (SSR Node/Nitro + ORM + PostgreSQL) con un Dockerfile multi-stage y stacks de Compose para desarrollo, QA y producción (Dokploy/Traefik). Úsala al dockerizar un proyecto nuevo, agregar un entorno de QA/staging, o revisar Dockerfiles y docker-compose de una app Node con base de datos. Basada en un proyecto Nuxt 4 + Prisma 7 pero adaptable a Next, Remix, Nest, etc.
---

# Dockerizar una app full-stack

Plantilla y guía para contenerizar una app web con renderizado en servidor (SSR)
sobre Node, un ORM con migraciones (Prisma) y PostgreSQL. Da tres entornos
coherentes —**desarrollo**, **QA** y **producción**— desde **un solo Dockerfile
multi-stage**.

Fue extraída de un proyecto Nuxt 4 (Nitro) + Prisma 7, pero la estructura sirve
para cualquier app Node full-stack. Los puntos a cambiar por stack están
marcados con `<<ADAPTAR>>` en los archivos de `references/`.

## Cuándo usar esta skill

- Dockerizar un proyecto que aún no tiene Docker.
- Añadir un entorno de **QA/staging** a un proyecto que solo tiene dev y prod.
- Revisar o mejorar un `Dockerfile` / `docker-compose` existente de una app Node
  con base de datos.
- Preparar un despliegue en **Dokploy** (u otro orquestador con Traefik).

## Principios (el "porqué", que es lo reutilizable)

1. **Un Dockerfile, varias etapas.** Instala y compila en etapas "gordas"
   (`deps`, `build`) y copia **solo el artefacto final** a una imagen de runtime
   mínima. La imagen de producción no lleva código fuente, ni devDependencies,
   ni el gestor de paquetes.
2. **Las migraciones y el seed corren al ARRANCAR, nunca en `docker build`.**
   En build no hay base de datos. Un ORM que exige `DATABASE_URL` al cargar su
   config recibe un valor *dummy* vía `ARG` que no persiste en la imagen.
3. **Producción por red interna.** app, db y nginx hablan por una red privada de
   Docker; **ningún puerto se publica al host**. El único borde público lo pone
   el orquestador (Traefik/Dokploy) con TLS.
4. **nginx delante del SSR.** Sirve estáticos inmutables desde disco (cache de 1
   año, llevan hash) y hace *proxy* de SSR + `/api` al servidor de la app. Menos
   carga sobre Node.
5. **Endurecimiento por defecto.** Usuario no-root, `no-new-privileges`, límites
   de CPU/memoria, healthchecks en cada servicio.
6. **QA = clon de producción.** Mismas imágenes y etapas; solo cambian datos,
   acceso y (opcionalmente) el seed. Lo que pruebas en QA se comporta como prod.

## Anatomía del Dockerfile multi-stage

```
base ─┬─> deps ─┬─> dev            (hot-reload; código por bind-mount)
      │         └─> build ─┬─> production   (Node + artefacto compilado)
      │                    └─> nginx        (estáticos + proxy inverso)
```

| Etapa        | Para qué | Se usa en |
| ------------ | -------- | --------- |
| `base`       | Node + gestor de paquetes + libs del SO | (interna) |
| `deps`       | `node_modules` completos (dev+prod) con cache | build/dev |
| `dev`        | servidor de desarrollo con hot-reload | dev |
| `build`      | genera cliente del ORM + compila; tiene el CLI del ORM | build, servicio `migrate` |
| `production` | imagen mínima que ejecuta el servidor compilado | QA, prod |
| `nginx`      | sirve estáticos y hace proxy al servidor | QA, prod |

Ver [references/Dockerfile](references/Dockerfile).

## Los tres entornos

| Aspecto | Desarrollo | QA / Staging | Producción |
| --- | --- | --- | --- |
| Archivo | `docker-compose.yml` | `docker-compose.qa.yml` | `docker-compose.prod.yml` |
| Imagen app | etapa `dev` | etapa `production` | etapa `production` |
| Código | bind-mount + HMR | horneado en la imagen | horneado en la imagen |
| Puertos al host | app y db publicados | solo nginx (o dominio QA) | **ninguno** (Traefik enruta) |
| Base de datos | volumen `pgdata-dev` | volumen `pgdata-qa` (aislado) | volumen `pgdata` |
| Migraciones | entrypoint al arrancar | servicio one-shot `migrate` | servicio one-shot `migrate` |
| Seed | sí (idempotente) | sí (fixtures de prueba) | opcional |
| Frente público | Nuxt dev server | nginx | nginx + Traefik/TLS |
| `NODE_ENV` | development | production | production |

- Desarrollo: [references/docker-compose.dev.yml](references/docker-compose.dev.yml)
- QA: [references/docker-compose.qa.yml](references/docker-compose.qa.yml)
- Producción: [references/docker-compose.prod.yml](references/docker-compose.prod.yml)

### Sobre QA (lo que suele faltar)

QA es producción con cuatro diferencias, todas marcadas `[QA-n]` en el compose:

- `[QA-1]` **BD y volumen propios** (`pgdata-qa`): datos desechables, aislados de prod.
- `[QA-2]` **nginx publicado a un puerto del host** (`QA_HTTP_PORT`, por defecto
  `8080`) para entrar sin dominio ni TLS. En Dokploy: borra el bloque `ports` y
  asigna un **dominio de QA** (p. ej. `qa.tu-dominio.com`) desde la UI, igual que prod.
- `[QA-3]` **Seed de fixtures** siempre activo (hazlo idempotente).
- `[QA-4]` **`NODE_ENV=production`** a propósito: QA valida el comportamiento real.

## Arquitectura de runtime (QA / prod)

```
Internet
   │  TLS + routing
Traefik            ← lo gestiona Dokploy (en QA local, se omite)
   │
nginx     ← estáticos + proxy inverso              [red interna]
   │
app       ← servidor SSR (Nitro) + API             [red interna]
   │
migrate   ← one-shot: migrate deploy + seed, luego termina
   │
db        ← PostgreSQL                             [red interna]
```

El servicio `app` solo arranca cuando `db` está *healthy* **y** `migrate`
terminó con éxito (`service_completed_successfully`).

## Cómo aplicarla a un proyecto

1. Copia a la raíz del proyecto:
   - `references/Dockerfile` → `Dockerfile`
   - `references/.dockerignore` → `.dockerignore`
   - `references/docker-compose.dev.yml` → `docker-compose.yml`
   - `references/docker-compose.qa.yml` → `docker-compose.qa.yml`
   - `references/docker-compose.prod.yml` → `docker-compose.prod.yml`
   - `references/docker-entrypoint.sh` → `docker/docker-entrypoint.sh`
   - `references/migrate-and-seed.sh` → `docker/migrate-and-seed.sh`
   - `references/nginx.default.conf` → `docker/nginx/default.conf`
   - `references/.env.example` → `.env.example`
2. `chmod +x docker/*.sh`
3. Resuelve cada `<<ADAPTAR>>` (ver checklist).
4. Prueba dev: `docker compose up --build`.
5. Prueba prod en local (ver más abajo). Añade QA cuando lo necesites.

### Checklist de adaptación (`<<ADAPTAR>>`)

- [ ] **Versión de Node** (`FROM node:XX-alpine`) igual a la del proyecto.
- [ ] **Gestor de paquetes**: pnpm vía corepack. Si usas npm/yarn, cambia
      `install`, el `--frozen-lockfile`, el cache-mount y el nombre del lockfile.
- [ ] **Libs del SO** que pida tu ORM/driver (aquí `openssl libc6-compat`).
- [ ] **Artefacto de build**: la ruta que copias a `production` y a `nginx`
      (aquí `/app/.output` y `/app/.output/public` de Nitro). En Next sería
      `.next/standalone` + `.next/static`, etc.
- [ ] **Comando de arranque** en `production` (`node .output/server/index.mjs`).
- [ ] **Endpoint del healthcheck** de la app.
- [ ] **Comandos del ORM**: `generate`, `migrate deploy`, `db seed`. Si no usas
      Prisma, ajústalos (o elimina el servicio `migrate` si no hay migraciones).
- [ ] **Variables `DATABASE_URL` dummy** en el `ARG` de build si tu ORM la exige.
- [ ] **`upstream` y `location /_nuxt/`** del nginx según tu framework.
- [ ] **Variables de entorno** de `app` en los compose (SMTP, secretos, etc.).
- [ ] Nombres de red/volúmenes/servicio a gusto del proyecto.

## Comandos

```bash
# Desarrollo (hot-reload)
docker compose up --build
docker compose logs -f app
docker compose exec app pnpm exec prisma migrate dev   # crear NUEVA migración
docker compose exec db psql -U app_user -d app_db
docker compose down          # parar; -v también borra datos (DESTRUCTIVO)

# QA / staging
docker compose -f docker-compose.qa.yml --env-file .env.qa up --build -d
# abre http://localhost:${QA_HTTP_PORT:-8080}

# Producción — probar en local (no publica puertos; verifica desde dentro)
docker compose -f docker-compose.prod.yml up --build -d
docker compose -f docker-compose.prod.yml exec nginx wget -qO- http://127.0.0.1/healthz
docker compose -f docker-compose.prod.yml exec nginx wget -qO- http://127.0.0.1/ | head
```

> Dentro del contenedor usa `127.0.0.1` (no `localhost`): `localhost` puede
> resolver a IPv6 mientras nginx escucha en IPv4.

## Despliegue en Dokploy (prod y QA)

1. Crea una aplicación tipo **Docker Compose** apuntando al repo y al archivo
   (`docker-compose.prod.yml` o `docker-compose.qa.yml`).
2. Define las **variables de entorno** en la UI de Dokploy (no subas `.env`):
   `POSTGRES_USER/PASSWORD/DB`, `APP_NAME`, `APP_URL`, `NUXT_SECRET`,
   `NUXT_SESSION_PASSWORD`, `SMTP_*`.
3. En **Domains**, asigna el dominio al servicio **`nginx`**, puerto **80**.
   Dokploy genera las labels de Traefik y emite el TLS (Let's Encrypt) solo.
   Para QA, en su compose borra el bloque `ports` de `nginx` y usa un dominio de QA.
4. Apunta el DNS al VPS y despliega.

No declares labels de Traefik ni la red `dokploy-network` en el compose: Dokploy
conecta el servicio expuesto a su red automáticamente.

## Errores comunes que evita esta plantilla

- Correr migraciones/seed en `docker build` → falla (no hay BD). Van al arranque.
- Publicar el puerto de Postgres en producción → nunca; solo red interna.
- Meter `.env` o `node_modules` del host en la imagen → los excluye `.dockerignore`.
- Seed no idempotente que corre en cada arranque → duplica datos. Usa `upsert`.
- Ejecutar el contenedor como root → usuario `appuser` no-root.
- `localhost` en healthchecks dentro del contenedor → usa `127.0.0.1`.
