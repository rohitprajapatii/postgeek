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

# Fix git ownership issue for Flutter directory
RUN git config --global --add safe.directory /flutter

WORKDIR /app/frontend

# Copy frontend files and build
COPY frontend/ ./
RUN chown -R nobody:nogroup /app/frontend
USER nobody
RUN flutter pub get
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