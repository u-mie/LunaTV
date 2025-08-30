# ---- 构建阶段 (固定用 amd64 编译 swc) ----
FROM --platform=linux/amd64 node:20-alpine AS builder
RUN corepack enable && corepack prepare pnpm@latest --activate
WORKDIR /app

COPY package.json pnpm-lock.yaml ./
RUN pnpm install --frozen-lockfile
COPY . .
ENV DOCKER_ENV=true
RUN pnpm run build

# ---- 运行阶段 (各平台对应运行时) ----
FROM node:18-bullseye AS runner
RUN addgroup --system nodejs && adduser --system --ingroup nodejs nextjs

WORKDIR /app
ENV NODE_ENV=production
ENV HOSTNAME=0.0.0.0
ENV PORT=3000
ENV DOCKER_ENV=true

COPY --from=builder /app/.next/standalone ./ 
COPY --from=builder /app/scripts ./scripts
COPY --from=builder /app/start.js ./start.js
COPY --from=builder /app/public ./public
COPY --from=builder /app/.next/static ./.next/static

USER nextjs
EXPOSE 3000
CMD ["node", "start.js"]
