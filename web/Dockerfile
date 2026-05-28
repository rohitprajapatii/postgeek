# PostGeek Next.js web frontend — multi-stage, standalone output.
# Build from the repository root:  docker build -f web/Dockerfile .

FROM node:20-alpine AS deps
WORKDIR /app
COPY web/package.json web/package-lock.json ./
RUN npm ci

FROM node:20-alpine AS build
WORKDIR /app
# Baked-in default backend URL (overridable at runtime in the UI).
ARG NEXT_PUBLIC_DEFAULT_API_URL=http://localhost:3000
ENV NEXT_PUBLIC_DEFAULT_API_URL=$NEXT_PUBLIC_DEFAULT_API_URL
ENV NEXT_TELEMETRY_DISABLED=1
COPY --from=deps /app/node_modules ./node_modules
COPY web/ ./
RUN npm run build

FROM node:20-alpine AS runner
WORKDIR /app
ENV NODE_ENV=production
ENV NEXT_TELEMETRY_DISABLED=1
ENV PORT=3001
ENV HOSTNAME=0.0.0.0

# Run as a non-root user.
RUN addgroup -g 1001 -S nodejs && adduser -S nextjs -u 1001

COPY --from=build /app/public ./public
COPY --from=build --chown=nextjs:nodejs /app/.next/standalone ./
COPY --from=build --chown=nextjs:nodejs /app/.next/static ./.next/static

USER nextjs
EXPOSE 3001
CMD ["node", "server.js"]
