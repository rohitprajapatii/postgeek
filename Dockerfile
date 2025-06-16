# Backend build stage
FROM node:18-alpine AS backend-build

WORKDIR /app/backend

COPY backend/package*.json ./
RUN npm ci

COPY backend/ ./
RUN npm run build

# Frontend build stage
FROM debian:bullseye-slim AS frontend-build

# Install required packages
RUN apt-get update && apt-get install -y \
    curl \
    git \
    unzip \
    xz-utils \
    zip \
    libglu1-mesa \
    wget \
    && rm -rf /var/lib/apt/lists/*

# Download and install Flutter
RUN git clone https://github.com/flutter/flutter.git /flutter
ENV PATH="/flutter/bin:${PATH}"
RUN flutter channel stable
RUN flutter upgrade
RUN flutter config --enable-web

# Change ownership of Flutter directory to nobody:nogroup
RUN chown -R nobody:nogroup /flutter

WORKDIR /app/frontend

# Copy pubspec files first for better caching
COPY frontend/pubspec.yaml frontend/pubspec.lock ./
RUN chown -R nobody:nogroup /app/frontend

# Create home directory for nobody user
RUN mkdir -p /home/nobody && chown nobody:nogroup /home/nobody
ENV HOME=/home/nobody

USER nobody

# Configure git for the nobody user
RUN git config --global --add safe.directory /flutter

# Install dependencies first
RUN flutter pub get

# Switch back to root to copy files and change ownership
USER root

# Copy the rest of the frontend files
COPY frontend/ ./

# Change ownership of all files to nobody
RUN chown -R nobody:nogroup /app/frontend

# Switch back to nobody user
USER nobody

# Build the web app
RUN flutter build web --release

# Switch back to root to fix permissions and handle missing assets
USER root

# Ensure icons are properly copied (Flutter build sometimes misses them)
RUN if [ -d "/app/frontend/web/icons" ]; then \
        cp -r /app/frontend/web/icons /app/frontend/build/web/ || echo "Icons copy failed"; \
    fi

# Ensure critical asset files are present (regenerate if missing)
RUN cd /app/frontend && \
    if [ ! -f "build/web/assets/FontManifest.json" ] || [ ! -f "build/web/assets/AssetManifest.json" ]; then \
        echo "Critical asset files missing, rebuilding..."; \
        flutter build web --release; \
    fi

# Fix permissions on build output
RUN chown -R root:root /app/frontend/build/web
RUN chmod -R 755 /app/frontend/build/web

# Backend production stage
FROM node:18-alpine AS backend

WORKDIR /app/backend

COPY --from=backend-build /app/backend/dist ./dist
COPY --from=backend-build /app/backend/package*.json ./

RUN npm ci --only=production

EXPOSE 3000
CMD ["node", "dist/main.js"]

# Frontend production stage
FROM nginx:alpine AS frontend

# Copy nginx configuration
COPY docker/nginx.conf /etc/nginx/nginx.conf

# Copy built frontend files with proper permissions
COPY --from=frontend-build --chown=root:root /app/frontend/build/web /usr/share/nginx/html

# Ensure all files have correct permissions
RUN chmod -R 755 /usr/share/nginx/html
RUN find /usr/share/nginx/html -type f -exec chmod 644 {} \;

EXPOSE 80
CMD ["nginx", "-g", "daemon off;"]