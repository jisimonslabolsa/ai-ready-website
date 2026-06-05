FROM node:20-alpine AS deps
WORKDIR /app
COPY package*.json ./
RUN npm install --legacy-peer-deps

FROM node:20-alpine AS builder
WORKDIR /app
COPY --from=deps /app/node_modules ./node_modules
COPY . .

# Variables necesarias en build time para que Next.js no falle
ARG FIRECRAWL_API_KEY=placeholder
ARG OPENAI_API_KEY=placeholder
ENV FIRECRAWL_API_KEY=$FIRECRAWL_API_KEY
ENV OPENAI_API_KEY=$OPENAI_API_KEY
ENV NEXT_TELEMETRY_DISABLED=1

# Evitar errores de tipo en build
ENV NODE_OPTIONS="--max-old-space-size=4096"

RUN npm run build

FROM node:20-alpine AS runner
WORKDIR /app
ENV NODE_ENV=production
ENV NEXT_TELEMETRY_DISABLED=1
COPY --from=builder /app/.next/standalone ./
COPY --from=builder /app/.next/static ./.next/static
COPY --from=builder /app/public ./public
EXPOSE 3000
CMD ["node", "server.js"]
