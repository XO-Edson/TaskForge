FROM node:22-alpine

RUN apk update && apk upgrade --no-cache \
    && npm install --global npm@12.2.1

WORKDIR /app

COPY package*.json ./
RUN npm ci --omit=dev

COPY src ./src

EXPOSE 4000

CMD ["npm", "start"]
