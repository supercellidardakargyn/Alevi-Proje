# syntax=docker/dockerfile:1.7
FROM node:22-bookworm-slim AS build
WORKDIR /workspace

COPY packages/config/package.json packages/config/tsconfig.json ./packages/config/
COPY packages/config/src ./packages/config/src
COPY packages/contracts/package.json packages/contracts/tsconfig.json ./packages/contracts/
COPY packages/contracts/src ./packages/contracts/src
COPY services/api/package.json services/api/tsconfig.json ./services/api/
COPY services/api/prisma ./services/api/prisma
COPY services/api/src ./services/api/src
COPY services/api/.env.example ./services/api/.env.example

RUN npm install --prefix packages/config && npm install --prefix packages/contracts && npm install --prefix services/api
RUN npm run build --prefix packages/config && npm run build --prefix packages/contracts
RUN npm run prisma:generate --prefix services/api && npm run build --prefix services/api

FROM node:22-bookworm-slim AS runtime
ENV NODE_ENV=production
WORKDIR /app

COPY --from=build /workspace/packages/config/package.json ./packages/config/package.json
COPY --from=build /workspace/packages/config/dist ./packages/config/dist
COPY --from=build /workspace/packages/contracts/package.json ./packages/contracts/package.json
COPY --from=build /workspace/packages/contracts/dist ./packages/contracts/dist
COPY --from=build /workspace/services/api/package.json ./services/api/package.json
COPY --from=build /workspace/services/api/node_modules ./services/api/node_modules
COPY --from=build /workspace/services/api/dist ./services/api/dist
COPY --from=build /workspace/services/api/prisma ./services/api/prisma

WORKDIR /app/services/api
USER node
EXPOSE 3000 9443
CMD ["node", "dist/src/server.js"]
