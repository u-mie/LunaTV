# ---- 第 1 阶段：安装依赖 ----
FROM --platform=linux/amd64 node:20-alpine AS deps

# 启用 corepack 并激活 pnpm
RUN corepack enable && corepack prepare pnpm@latest --activate

WORKDIR /app

# 仅复制依赖清单，提高缓存利用率
COPY package.json pnpm-lock.yaml ./

# 安装所有依赖（含 devDependencies）
RUN pnpm install --frozen-lockfile

# ---- 第 2 阶段：构建项目 ----
FROM --platform=linux/amd64 node:20-alpine AS builder
RUN corepack enable && corepack prepare pnpm@latest --activate
WORKDIR /app

# 复制依赖
COPY --from=deps /app/node_modules ./node_modules
# 复制全部源代码
COPY . .

ENV DOCKER_ENV=true

# 构建生产版本
RUN pnpm run build

# ---- 第 3 阶段：生成运行时镜像 ----
FROM --platform=$TARGETPLATFORM node:18-bullseye AS runner

# 创建非 root 用户
RUN addgroup --system nodejs && adduser --system --ingroup nodejs nextjs

WORKDIR /app
ENV NODE_ENV=production
ENV HOSTNAME=0.0.0.0
ENV PORT=3000
ENV DOCKER_ENV=true

# 复制构建输出
COPY --from=builder --chown=nextjs:nodejs /app/.next/standalone ./
COPY --from=builder --chown=nextjs:nodejs /app/scripts ./scripts
COPY --from=builder --chown=nextjs:nodejs /app/start.js ./start.js
COPY --from=builder --chown=nextjs:nodejs /app/public ./public
COPY --from=builder --chown=nextjs:nodejs /app/.next/static ./.next/static

# 修复 public 目录权限，保证 nextjs 用户可写
RUN chown -R nextjs:nodejs /app/public

# 切换到非特权用户
USER nextjs

EXPOSE 3000

# 使用自定义启动脚本
CMD ["node", "start.js"]
