FROM node:20-bookworm-slim

WORKDIR /app

COPY package.json package-lock.json ./
RUN npm ci

COPY src ./src
COPY test ./test

EXPOSE 3000

USER node

CMD ["npm", "start"]
