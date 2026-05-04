# ---- Stage 1: Builder ----
FROM node:20-alpine AS builder

WORKDIR /app

# Copy dependency manifests first to leverage Docker layer caching
COPY package.json package-lock.json* ./

# Install all dependencies (excluding devDependencies)
RUN npm install --omit=dev

# Copy application source
COPY src/ ./src/

# ---- Stage 2: Production ----
FROM node:20-alpine AS production

WORKDIR /app

# Create a non-root user
RUN addgroup -S appgroup && adduser -S appuser -G appgroup

# Copy only the necessary artifacts from the builder stage
COPY --from=builder /app/node_modules ./node_modules
COPY --from=builder /app/package.json ./package.json
COPY --from=builder /app/src ./src

# Environment variables (defaults, overridden by Docker Compose)
ENV PORT=3000
ENV DB_HOST=database
ENV DB_PORT=5432
ENV DB_NAME=taskmanager
ENV DB_USER=appuser
ENV DB_PASSWORD=apppassword

# Expose the application port
EXPOSE 3000

# Switch to non-root user
USER appuser

# Start the application
CMD ["node", "src/index.js"]
