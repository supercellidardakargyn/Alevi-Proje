FROM node:22-bookworm-slim AS runtime
ENV NODE_ENV=production
ENV PORT=25577
WORKDIR /app
COPY services/gateway/package.json services/gateway/package-lock.json ./
RUN npm ci --omit=dev
COPY services/gateway/index.js ./index.js
USER node
EXPOSE 25577
CMD ["node", "index.js"]
