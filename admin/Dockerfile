FROM node:20-bookworm-slim

WORKDIR /app

COPY package.json package-lock.json ./
RUN npm ci

COPY . .

RUN chown -R node:node /app

EXPOSE 5173

USER node

CMD ["npm", "run", "dev", "--", "--host", "0.0.0.0"]
