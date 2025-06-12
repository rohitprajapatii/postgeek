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

# Copy built frontend files
COPY --from=frontend-build /app/frontend/build/web /usr/share/nginx/html

EXPOSE 80
CMD ["nginx", "-g", "daemon off;"]