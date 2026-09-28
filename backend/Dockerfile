FROM node:20-alpine

WORKDIR /usr/src/app

COPY package*.json ./

RUN npm ci --only=production

COPY . .

ENV PORT=5050
EXPOSE 5050

CMD ["node", "server.js"]
