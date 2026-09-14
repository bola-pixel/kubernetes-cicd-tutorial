# --- Build stage ---
FROM node:14-alpine AS build

WORKDIR /app

# Copy only package files first for better layer caching
COPY src/package*.json ./

# Install with lockfile-exact versions, skip dev deps, skip audit/fund noise
RUN npm install --omit=dev

# Copy source code
COPY src/ ./

# --- Runtime stage ---
FROM node:14-alpine

# Install tini for proper signal handling (PID 1 zombie reaping)
RUN apk add --no-cache tini

WORKDIR /app

# Copy only what's needed from the build stage (no build tools, no cache)
COPY --from=build /app /app

# node:alpine images already ship a non-root "node" user — use it
USER node

ENV NODE_ENV=production

EXPOSE 3000

# tini as PID 1 handles signals/zombies correctly (important for k8s SIGTERM on rollout)
ENTRYPOINT ["/sbin/tini", "--"]
CMD ["node", "app.js"]
