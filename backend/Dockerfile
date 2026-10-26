FROM node:22-alpine

RUN apk update && apk upgrade --no-cache

WORKDIR /app

COPY package*.json ./
RUN npm ci --omit=dev

COPY src ./src

RUN rm -rf /usr/local/lib/node_modules/npm \
    /usr/local/bin/npm \
    /usr/local/bin/npx

EXPOSE 4000

CMD ["node", "src/server.js"]

