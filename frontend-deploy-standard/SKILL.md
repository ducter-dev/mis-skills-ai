---
name: frontend-deploy-standard
description: "Standardized Docker and CI/CD setup for Vite-based frontend projects. Includes multi-stage builds, environment isolation (Dev/Staging/Prod), and automatic Git commit hash persistence."
---

# Frontend Deployment Standard

Use this skill to quickly scaffold or verify the Docker and CI/CD infrastructure for a Vite-based frontend project.

## Key Features
- **Git Auto-detection**: Automatically captures commit hash and date during build (even if build-args are missing).
- **Multi-stage Builds**: Minimal production images using Nginx.
- **Environment Isolation**: Separate configurations for Local Development, Staging (QA), and Production.
- **CI/CD Integrated**: Workflows for GitHub Actions and Dokploy.

---

## 🚀 Workflow

1.  **Analyze Project**: Check if it's a Vite project and identify its build command (usually `npm run build`).
2.  **Generate Configs**: Create the Docker, Compose, and Workflows files using the templates below.
3.  **Environment Setup**: Prompt the user to configure variables in the `.env` or Dokploy dashboard.
4.  **Verification**: Build locally to ensure the `.git` folder is correctly read and the `commit.txt` is generated.

---

## 🐳 Docker Templates

### [.dockerignore]
> [!IMPORTANT]
> Do NOT ignore `.git` if you want auto-detection of commit hashes in local builds (e.g. Dokploy).

```ignore
# .git (uncomment if you want to allow commit hash detection during build context)
node_modules
dist
.env
.gitignore
.dockerignore
README.md
docs
npm-debug.log
error.log
```

### [Dockerfile.staging / Dockerfile.prod]
Pattern for multi-stage build with Git persistence.

```dockerfile
# Build stage
FROM node:22-alpine AS build-stage
RUN apk add --no-cache git

WORKDIR /app

COPY package*.json ./
RUN npm install

COPY . .

# Optional ARGs (passed by GHA or CI)
ARG VITE_GIT_COMMIT_HASH
ARG VITE_GIT_COMMIT_DATE
# Add other app-specific ARGs here

# Generate commit.txt (uses ARG if available, fallback to git command)
RUN HASH=${VITE_GIT_COMMIT_HASH:-$(git rev-parse --short HEAD 2>/dev/null || echo "unknown")} && \
    DATE=${VITE_GIT_COMMIT_DATE:-$(git log -1 --format=%cd 2>/dev/null || echo "unknown")} && \
    echo "Commit: $HASH" > commit.txt && \
    echo "Date: $DATE" >> commit.txt

RUN npm run build

# Production stage (Nginx)
FROM nginx:stable-alpine AS production-stage

# Persist info in the final image
COPY --from=build-stage /app/dist /usr/share/nginx/html
COPY --from=build-stage /app/commit.txt /usr/share/nginx/html/commit.txt
COPY nginx.conf /etc/nginx/conf.d/default.conf

EXPOSE 80
CMD ["nginx", "-g", "daemon off;"]
```

---

## ⚙️ Orchestration Templates

### [docker-compose.staging.yml]
```yaml
services:
  app-staging:
    image: ${DOCKER_REGISTRY}/${DOCKER_IMAGE_NAME}:${IMAGE_TAG}
    container_name: your-app-staging
    restart: unless-stopped
    build:
      context: .
      dockerfile: Dockerfile.staging
      args:
        - VITE_GIT_COMMIT_HASH=${VITE_GIT_COMMIT_HASH}
        - VITE_GIT_COMMIT_DATE=${VITE_GIT_COMMIT_DATE}
    ports:
      - "${APP_PORT:-3000}:80"
    networks:
      - app-network

networks:
  app-network:
    driver: bridge
```

---

## 🛠 CI/CD Templates

### [.github/workflows/staging.yml]
- Build and push to GHCR.
- Automatic deployment to Dokploy via API.

```yaml
# ... checkout, docker login, metadata extraction ...
      - name: Build and push Docker image
        uses: docker/build-push-action@v5
        with:
          context: .
          file: ./Dockerfile.staging
          push: true
          tags: ${{ steps.meta.outputs.tags }}
          build-args: |
            VITE_GIT_COMMIT_HASH=${{ github.sha }}
            VITE_GIT_COMMIT_DATE=$(date -u +"%Y-%m-%dT%H:%M:%SZ")
# ... deployment trigger ...
```

---

## 📖 Best Practices
1.  **Vite Define**: Use `define` in `vite.config.js` to inject versioning into the JS bundle.
2.  **Commit File**: Always deploy `commit.txt` to help debug which version is running in a specific container.
3.  **No Default Unknown**: In compose files, prefer empty values over `:unknown` string to let Vite's logic handle detection.
