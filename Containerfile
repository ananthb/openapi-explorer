FROM docker.io/library/node:16.9.1-alpine AS build
WORKDIR /app
COPY . .
RUN yarn install --dev && yarn build

FROM ghcr.io/ananthb/thttpd-container
COPY --from=build /app/public /srv
