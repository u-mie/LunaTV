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

# 修复权限
RUN chown -R nextjs:nodejs /app/public

USER nextjs
EXPOSE 3000
CMD ["node", "start.js"]
