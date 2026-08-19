# ---- Build stage ----
FROM node:20-alpine AS build
WORKDIR /usr/src/app
COPY app/package*.json ./
RUN npm ci
COPY app/ .

# ---- Runtime stage ----
FROM node:20-alpine
WORKDIR /usr/src/app
ENV NODE_ENV=production
COPY --from=build /usr/src/app/node_modules ./node_modules
COPY --from=build /usr/src/app/package*.json ./
COPY --from=build /usr/src/app/server.js ./

# Run as non-root user
RUN addgroup -S appgroup && adduser -S appuser -G appgroup
USER appuser

EXPOSE 3000
CMD ["node", "server.js"]
