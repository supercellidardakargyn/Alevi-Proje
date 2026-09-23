FROM node:22-bookworm-slim AS build
WORKDIR /app
COPY apps/admin/package.json apps/admin/package-lock.json ./
RUN npm ci
COPY apps/admin ./
ARG NEXT_PUBLIC_ADMIN_API_URL=https://api.sonalis.com.tr
ENV NEXT_PUBLIC_ADMIN_API_URL=$NEXT_PUBLIC_ADMIN_API_URL
RUN npm run build

FROM node:22-bookworm-slim AS runtime
ENV NODE_ENV=production
WORKDIR /app
COPY --from=build /app/package.json ./package.json
COPY --from=build /app/node_modules ./node_modules
COPY --from=build /app/.next ./.next
COPY --from=build /app/public ./public
COPY --from=build /app/next.config.mjs ./next.config.mjs
USER node
EXPOSE 3000
CMD ["npm", "start"]
