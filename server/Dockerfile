FROM node:20-alpine AS builder
WORKDIR /app
RUN apk add --no-cache openssl
COPY package*.json ./
RUN npm ci
COPY . .
RUN npx prisma generate
RUN npm run build

FROM node:20-alpine AS runner
WORKDIR /app
RUN apk add --no-cache openssl curl && \
    addgroup --system --gid 1001 nodejs && \
    adduser --system --uid 1001 appuser
COPY --from=builder /app/package*.json ./
COPY --from=builder /app/node_modules ./node_modules
COPY --from=builder /app/dist ./dist
COPY --from=builder /app/prisma ./prisma
COPY --from=builder /app/src/prompts ./dist/prompts
COPY --from=builder /app/src/seed.ts ./src/seed.ts
RUN printf '#!/bin/sh\nset -e\nif [ "$1" = "seed" ]; then\n  echo "Running seed..."\n  cd /app && npx tsx src/seed.ts\n  exit $?\nfi\necho "Running migrations..."\nnpx prisma migrate deploy\necho "Starting server..."\nexec node dist/index.js\n' > /entrypoint.sh && chmod +x /entrypoint.sh
USER appuser
EXPOSE 3000
ENTRYPOINT ["/entrypoint.sh"]
