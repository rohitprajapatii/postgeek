#!/bin/sh

# Start Nginx
nginx -g "daemon off;" &

# Start NestJS backend
cd /app/backend && node dist/main.js