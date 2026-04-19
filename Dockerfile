# ═══════════════════════════════════════════════════════
# STAGE 1: builder
# Installs dependencies — has build tools, bigger image
# ═══════════════════════════════════════════════════════
FROM node:20-alpine AS builder

WORKDIR /build

# Copy dependency files first (better Docker layer caching)
# If package.json doesn't change, Docker skips npm ci on next build
COPY app/package*.json ./

# Install exact versions from package-lock.json
# --frozen-lockfile = error if lock file is out of date
RUN npm ci

# ═══════════════════════════════════════════════════════
# STAGE 2: runtime
# Only what's needed to RUN the app — much smaller image
# ═══════════════════════════════════════════════════════
FROM node:20-alpine

WORKDIR /app

# Copy installed packages from builder (not the build tools)
COPY --from=builder /build/node_modules ./node_modules

# Copy app source code
COPY app/ ./

# Create non-root user (security best practice)
# Running as root inside a container is a security risk
RUN addgroup -S appgroup && adduser -S appuser -G appgroup
RUN chown -R appuser:appgroup /app
USER appuser

# Document which port the app listens on (informational)
EXPOSE 3000

# Start the app
CMD ["node", "server.js"]